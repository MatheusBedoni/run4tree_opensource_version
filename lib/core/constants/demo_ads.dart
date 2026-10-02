import '../utils/env.dart';

/// Modo de anúncios de demonstração, só para gravar o vídeo do Shipaton.
///
/// Liga no `.env`:
///
/// ```
/// DEMO_ADS=true
/// DEMO_AD_REVENUE_USD=0.05   # opcional
/// ```
///
/// Ligado, o app troca o AdMob por uma tela e um banner fictícios, e cada
/// "anúncio" credita sementes como se tivesse sido verificado. Nada é enviado
/// ao AdMob nem ao tracking da RevenueCat, então os dados reais não se
/// misturam com os da gravação.
///
/// ⚠️ O `.env` vai dentro do app: volte para `DEMO_ADS=false` antes de gerar
/// qualquer build para a loja.
class DemoAds {
  DemoAds._();

  static bool get enabled => envOrNull('DEMO_ADS')?.toLowerCase() == 'true';

  /// Receita creditada por anúncio de vídeo fictício. Um valor alto enche o
  /// anel pessoal em poucos anúncios.
  static double get revenuePerAdUsd =>
      double.tryParse(envOrNull('DEMO_AD_REVENUE_USD') ?? '') ?? 0.01;

  /// Tempo até o botão de fechar aparecer na tela do anúncio fictício.
  static const Duration countdown = Duration(seconds: 5);
}
