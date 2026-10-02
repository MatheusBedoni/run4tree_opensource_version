import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../observability/critical_flow_telemetry.dart';
import '../utils/purchases_safe_call.dart';

/// Resultado de uma sessão de anúncio.
class AdWatchResult {
  final bool success;

  /// Receita real (USD) que esse anúncio pagou, vinda do callback
  /// `onPaidEvent` do AdMob. Zero quando [success] é falso.
  final double revenueUsd;

  /// Verdadeiro quando [revenueUsd] é um valor estimado (fallback), porque
  /// a conta AdMob ainda não reporta receita por impressão para essa unidade
  /// de anúncio — ver `_estimatedRevenuePerViewUsd`.
  final bool isEstimatedRevenue;

  final String? errorMessage;

  /// `clientTransactionId` da verificação server-side da RevenueCat que
  /// confirmou este anúncio — o recibo auditável de que ele foi assistido.
  final String? rewardTransactionId;

  const AdWatchResult.success(
    this.revenueUsd, {
    required this.isEstimatedRevenue,
    this.rewardTransactionId,
  }) : success = true,
       errorMessage = null;

  const AdWatchResult.failure(this.errorMessage)
    : success = false,
      revenueUsd = 0,
      isEstimatedRevenue = false,
      rewardTransactionId = null;
}

/// Carrega e exibe um anúncio "rewarded interstitial" — aparece
/// automaticamente (sem exigir um botão do usuário), mas concede uma
/// recompensa como um anúncio recompensado normal. Usado nos momentos de
/// início e fim de uma corrida.
///
/// Reporta cada evento do ciclo de vida do anúncio para a RevenueCat
/// (`Purchases.adTracker`) e só confirma a recompensa depois da verificação
/// server-side (AdMob SSV) via [Purchases.generateRewardVerificationToken]/
/// [Purchases.pollRewardVerification] — a recompensa nunca é concedida
/// apenas pelo callback client-side do AdMob.
class RewardedInterstitialAdService {
  const RewardedInterstitialAdService();

  static const _mediatorName = AdMediatorName.adMob;
  static const _adFormat = AdFormat.rewardedInterstitial;

  /// Usado só quando a conta AdMob ainda não reporta receita por impressão
  /// (`onPaidEvent` nunca dispara nesse caso — comum com unidades de teste ou
  /// contas sem "impression-level ad revenue" habilitado). Ajuste no .env
  /// assim que tiver dados reais de eCPM da sua conta.
  double get _estimatedRevenuePerViewUsd {
    final raw = dotenv.env['ESTIMATED_AD_REVENUE_PER_VIEW_USD'];
    return double.tryParse(raw ?? '') ?? 0.01;
  }

  String get _adUnitId {
    final key = Platform.isIOS
        ? 'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_IOS'
        : 'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ANDROID';
    return dotenv.env[key] ?? '';
  }

  /// [placement] identifica o momento da corrida em que o anúncio é exibido
  /// (ex: `run_start`, `run_end`) — repassado ao tracking da RevenueCat.
  Future<AdWatchResult> watchAd({required String placement}) async {
    await CriticalFlowTelemetry.adWatchStarted(placement);
    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) {
      await CriticalFlowTelemetry.adWatchFailed(
        placement: placement,
        reason: 'ad_unit_not_configured',
      );
      return const AdWatchResult.failure('ad_unit_not_configured');
    }

    final completer = Completer<AdWatchResult>();

    await RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _onAdLoaded(ad, placement, completer),
        onAdFailedToLoad: (error) {
          fireAndForgetPurchasesCall(
            'trackAdFailedToLoad',
            () => Purchases.adTracker.trackAdFailedToLoad(
              AdFailedToLoadData(
                mediatorName: _mediatorName,
                adFormat: _adFormat,
                placement: placement,
                adUnitId: adUnitId,
                mediatorErrorCode: error.code,
              ),
            ),
          );
          if (!completer.isCompleted) {
            unawaited(
              CriticalFlowTelemetry.adWatchFailed(
                placement: placement,
                reason: 'load_failed',
              ),
            );
            completer.complete(
              AdWatchResult.failure('load_failed: ${error.message}'),
            );
          }
        },
      ),
    );

    return completer.future;
  }

  Future<void> _onAdLoaded(
    RewardedInterstitialAd ad,
    String placement,
    Completer<AdWatchResult> completer,
  ) async {
    var rewardEarned = false;
    double? capturedRevenueUsd;

    try {
      final impressionId = ad.responseInfo?.responseId;
      if (impressionId == null) {
        ad.dispose();
        await CriticalFlowTelemetry.adWatchFailed(
          placement: placement,
          reason: 'missing_impression_id',
        );
        completer.complete(
          const AdWatchResult.failure('missing_impression_id'),
        );
        return;
      }

      fireAndForgetPurchasesCall(
        'trackAdLoaded',
        () => Purchases.adTracker.trackAdLoaded(
          AdLoadedData(
            mediatorName: _mediatorName,
            adFormat: _adFormat,
            placement: placement,
            adUnitId: ad.adUnitId,
            impressionId: impressionId,
          ),
        ),
      );

      final token = await Purchases.generateRewardVerificationToken(
        impressionId,
      );

      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: token.appUserID,
          customData: token.customData,
        ),
      );

      // Reporta receita por impressão quando a conta AdMob tem "impression-level
      // ad revenue" habilitado; sem isso o callback simplesmente nunca dispara,
      // e ficamos com o valor estimado como fallback (ver `success` abaixo).
      ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
        capturedRevenueUsd = valueMicros / 1e6;
        fireAndForgetPurchasesCall(
          'trackAdRevenue',
          () => Purchases.adTracker.trackAdRevenue(
            AdRevenueData(
              mediatorName: _mediatorName,
              adFormat: _adFormat,
              placement: placement,
              adUnitId: ad.adUnitId,
              impressionId: impressionId,
              revenueMicros: valueMicros.round(),
              currency: currencyCode,
              precision: _mapPrecision(precision),
            ),
          ),
        );
      };

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          fireAndForgetPurchasesCall(
            'trackAdDisplayed',
            () => Purchases.adTracker.trackAdDisplayed(
              AdDisplayedData(
                mediatorName: _mediatorName,
                adFormat: _adFormat,
                placement: placement,
                adUnitId: ad.adUnitId,
                impressionId: impressionId,
              ),
            ),
          );
        },
        onAdClicked: (ad) {
          fireAndForgetPurchasesCall(
            'trackAdOpened',
            () => Purchases.adTracker.trackAdOpened(
              AdOpenedData(
                mediatorName: _mediatorName,
                adFormat: _adFormat,
                placement: placement,
                adUnitId: ad.adUnitId,
                impressionId: impressionId,
              ),
            ),
          );
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!rewardEarned && !completer.isCompleted) {
            completer.complete(
              const AdWatchResult.failure('dismissed_without_reward'),
            );
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) {
            unawaited(
              CriticalFlowTelemetry.adWatchFailed(
                placement: placement,
                reason: 'show_failed',
              ),
            );
            completer.complete(
              AdWatchResult.failure('show_failed: ${error.message}'),
            );
          }
        },
      );

      await ad.show(
        onUserEarnedReward: (ad, reward) async {
          rewardEarned = true;
          // A verificação server-side confirma que o anúncio foi mesmo
          // assistido até o fim (anti-fraude) — o valor em USD creditado vem
          // de `onPaidEvent`, não do tipo de recompensa configurado no
          // dashboard da RevenueCat.
          final result = await safePurchasesCall(
            'pollRewardVerification',
            () => Purchases.pollRewardVerification(token.clientTransactionId),
          );

          if (completer.isCompleted) return;

          if (result != null && !result.failed) {
            final revenue = capturedRevenueUsd;
            unawaited(
              CriticalFlowTelemetry.adWatchCompleted(
                placement: placement,
                usedEstimatedRevenue: revenue == null,
              ),
            );
            completer.complete(
              AdWatchResult.success(
                revenue ?? _estimatedRevenuePerViewUsd,
                isEstimatedRevenue: revenue == null,
                rewardTransactionId: token.clientTransactionId,
              ),
            );
          } else {
            unawaited(
              CriticalFlowTelemetry.adWatchFailed(
                placement: placement,
                reason: 'verification_failed',
              ),
            );
            completer.complete(
              const AdWatchResult.failure('verification_failed'),
            );
          }
        },
      );
    } catch (e, st) {
      ad.dispose();
      debugPrint('RewardedInterstitialAdService error: $e');
      unawaited(
        CriticalFlowTelemetry.adWatchFailed(
          placement: placement,
          reason: 'unexpected_error',
          error: e,
          stackTrace: st,
        ),
      );
      if (!completer.isCompleted) {
        completer.complete(AdWatchResult.failure(e.toString()));
      }
    }
  }

  AdRevenuePrecision _mapPrecision(PrecisionType precision) {
    switch (precision) {
      case PrecisionType.precise:
        return AdRevenuePrecision.exact;
      case PrecisionType.publisherProvided:
        return AdRevenuePrecision.publisherDefined;
      case PrecisionType.estimated:
        return AdRevenuePrecision.estimated;
      case PrecisionType.unknown:
        return AdRevenuePrecision.unknown;
    }
  }
}
