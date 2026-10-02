import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/data/repositories/user_profile_repository_impl.dart';
import '../../../onboarding/domain/usecases/has_completed_onboarding_usecase.dart';

/// Splash inicial do app: mostra a arte em tela cheia (a mesma imagem usada no
/// splash nativo, então a transição nativo -> Flutter é imperceptível) enquanto
/// decide, em paralelo, se o usuário vai para a home ou para o login.
///
/// O rodapé credita a artista da ilustração e abre o Instagram dela ao toque.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Tempo mínimo que a arte fica na tela, mesmo que a rota resolva antes —
  /// evita um "piscar" da splash em aparelhos rápidos.
  static const Duration minimumDisplay = Duration(milliseconds: 2400);

  static const String artistHandle = 'ani.hikari';
  static const String artistProfileUrl = 'https://instagram.com/ani.hikari';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Dispara a leitura do perfil e o tempo mínimo juntos: o que demorar mais
    // manda no momento da navegação.
    final routeFuture = _resolveInitialRoute();
    await Future<void>.delayed(SplashPage.minimumDisplay);
    final route = await routeFuture;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// Decide a rota inicial: se o usuário já respondeu o questionário de
  /// boas-vindas, vai direto para a home; senão, passa pelo login/onboarding.
  Future<String> _resolveInitialRoute() async {
    final hasCompleted = await HasCompletedOnboardingUseCase(
      UserProfileRepositoryImpl(),
    )();
    return hasCompleted ? '/home' : '/login';
  }

  Future<void> _openArtistProfile() async {
    final uri = Uri.parse(SplashPage.artistProfileUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_screen.jpg', fit: BoxFit.cover),
          Align(
            alignment: AlignmentGeometry.center,
            child: Text(
              "RUN4TREE",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _ArtistCredit(
                label: l10n.splashArtCredit(SplashPage.artistHandle),
                onTap: _openArtistProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa de crédito no rodapé: um degradê escuro garante contraste sobre a
/// grama da ilustração e o texto inteiro é a área de toque.
class _ArtistCredit extends StatelessWidget {
  const _ArtistCredit({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 56, bottom: 20),
          child: Center(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.instagram,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
