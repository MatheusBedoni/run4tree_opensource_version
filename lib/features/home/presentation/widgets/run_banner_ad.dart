import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/constants/demo_ads.dart';
import '../../../../core/utils/purchases_safe_call.dart';
import 'demo_ad_page.dart';

/// Banner exibido durante a corrida — contribui com receita real (ou
/// estimada, quando a conta AdMob não reporta receita por impressão) para o
/// progresso de plantio de árvore, um pouco a cada recarga.
///
/// Recarrega periodicamente enquanto estiver montado, então corridas mais
/// longas contribuem mais.
class RunBannerAd extends StatefulWidget {
  final ValueChanged<double> onAdRevenue;

  /// Placement reportado à RevenueCat — separa a receita do banner das
  /// corridas pessoais (`run_banner`) da dos exercícios em grupo.
  final String placement;

  const RunBannerAd({
    super.key,
    required this.onAdRevenue,
    this.placement = 'run_banner',
  });

  @override
  State<RunBannerAd> createState() => _RunBannerAdState();
}

class _RunBannerAdState extends State<RunBannerAd> {
  static const _mediatorName = AdMediatorName.adMob;
  static const _adFormat = AdFormat.banner;
  static const _reloadInterval = Duration(seconds: 45);
  static const _paidEventGracePeriod = Duration(seconds: 2);

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Timer? _reloadTimer;
  int _loadCycle = 0;

  double get _estimatedRevenuePerViewUsd {
    final raw = dotenv.env['ESTIMATED_BANNER_AD_REVENUE_PER_VIEW_USD'];
    return double.tryParse(raw ?? '') ?? 0.002;
  }

  String get _adUnitId {
    final key = Platform.isIOS
        ? 'ADMOB_BANNER_AD_UNIT_IOS'
        : 'ADMOB_BANNER_AD_UNIT_ANDROID';
    return dotenv.env[key] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _reloadTimer = Timer.periodic(_reloadInterval, (_) => _loadBanner());
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBanner() {
    if (DemoAds.enabled) {
      // DEMO_ADS: banner fictício, creditando a mesma estimativa do real.
      if (!_isLoaded) setState(() => _isLoaded = true);
      widget.onAdRevenue(_estimatedRevenuePerViewUsd);
      return;
    }
    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) return;

    final cycle = ++_loadCycle;
    var paidEventFired = false;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || cycle != _loadCycle) {
            ad.dispose();
            return;
          }
          final previous = _bannerAd;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
          previous?.dispose();

          // Fallback: se a conta AdMob não reportar receita por impressão,
          // `onPaidEvent` nunca dispara — credita a estimativa depois de uma
          // breve espera para dar chance ao valor real chegar primeiro.
          Future.delayed(_paidEventGracePeriod, () {
            if (!paidEventFired && mounted && cycle == _loadCycle) {
              widget.onAdRevenue(_estimatedRevenuePerViewUsd);
            }
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          fireAndForgetPurchasesCall(
            'trackAdFailedToLoad',
            () => Purchases.adTracker.trackAdFailedToLoad(
              AdFailedToLoadData(
                mediatorName: _mediatorName,
                adFormat: _adFormat,
                placement: widget.placement,
                adUnitId: adUnitId,
                mediatorErrorCode: error.code,
              ),
            ),
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final impressionId = ad.responseInfo?.responseId;
          if (impressionId == null) return;
          paidEventFired = true;
          fireAndForgetPurchasesCall(
            'trackAdRevenue',
            () => Purchases.adTracker.trackAdRevenue(
              AdRevenueData(
                mediatorName: _mediatorName,
                adFormat: _adFormat,
                placement: widget.placement,
                adUnitId: adUnitId,
                impressionId: impressionId,
                revenueMicros: valueMicros.round(),
                currency: currencyCode,
                precision: _mapPrecision(precision),
              ),
            ),
          );
          widget.onAdRevenue(valueMicros / 1e6);
        },
      ),
    );

    ad.load();
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

  @override
  Widget build(BuildContext context) {
    if (DemoAds.enabled) {
      return _isLoaded ? const DemoBannerAd() : const SizedBox.shrink();
    }
    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
