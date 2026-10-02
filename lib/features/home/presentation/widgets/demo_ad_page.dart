import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/demo_ads.dart';
import '../../../../core/services/rewarded_interstitial_ad_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Mostra o anúncio de vídeo fictício ([DemoAds]) e devolve o resultado no
/// mesmo formato do [RewardedInterstitialAdService], para o resto do fluxo
/// (sementes, overlay, grupo) seguir igual ao do anúncio real.
Future<AdWatchResult> showDemoRewardedAd(
  NavigatorState navigator, {
  required String placement,
}) async {
  debugPrint('[Ad:$placement] DEMO_ADS — anúncio fictício');
  final watched = await navigator.push<bool>(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, _, _) => const DemoAdPage(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  if (watched != true) {
    return const AdWatchResult.failure('dismissed_without_reward');
  }
  return AdWatchResult.success(
    DemoAds.revenuePerAdUsd,
    isEstimatedRevenue: true,
    // As regras do Firestore exigem um recibo único por contribuição de grupo.
    rewardTransactionId:
        'demo-${DateTime.now().microsecondsSinceEpoch}-'
        '${math.Random().nextInt(1 << 32)}',
  );
}

/// Tela cheia no lugar do vídeo do anúncio: contagem regressiva e, no fim,
/// o botão de fechar — como um anúncio recompensado de verdade.
class DemoAdPage extends StatefulWidget {
  const DemoAdPage({super.key});

  @override
  State<DemoAdPage> createState() => _DemoAdPageState();
}

class _DemoAdPageState extends State<DemoAdPage> {
  late int _secondsLeft = DemoAds.countdown.inSeconds;
  Timer? _timer;

  bool get _canClose => _secondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_canClose) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const Center(child: _DemoAdCreative()),
              Positioned(top: 12, left: 12, child: _adBadge()),
              Positioned(top: 8, right: 8, child: _closeButton()),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Text(
                  _canClose
                      ? 'Reward earned: your seeds are on the way'
                      : 'Reward in $_secondsLeft s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Ad',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _closeButton() {
    if (!_canClose) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54),
        ),
        child: Text(
          '$_secondsLeft',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }
    return IconButton(
      onPressed: () => Navigator.of(context).pop(true),
      icon: const Icon(Icons.close, color: Colors.white, size: 28),
      tooltip: 'Close ad',
    );
  }
}

/// "Criativo" genérico do anúncio: não imita nenhuma marca real.
class _DemoAdCreative extends StatelessWidget {
  const _DemoAdCreative();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.bullhorn, color: Colors.white, size: 48),
          SizedBox(height: 20),
          Text(
            'Your ad here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Brands that pay for this video are paying for a real tree.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Banner fictício do tamanho do banner padrão (320×50).
class DemoBannerAd extends StatelessWidget {
  const DemoBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          const FaIcon(
            FontAwesomeIcons.bullhorn,
            size: 18,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your ad here · funds real trees',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
