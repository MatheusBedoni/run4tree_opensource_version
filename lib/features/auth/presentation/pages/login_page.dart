import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/data/repositories/user_profile_repository_impl.dart';
import '../../../onboarding/domain/usecases/has_completed_onboarding_usecase.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final HasCompletedOnboardingUseCase _hasCompletedOnboardingUseCase;

  bool _isCheckingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _hasCompletedOnboardingUseCase = HasCompletedOnboardingUseCase(
      UserProfileRepositoryImpl(),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    if (_isCheckingOnboarding) return;
    setState(() => _isCheckingOnboarding = true);

    final hasCompletedOnboarding = await _hasCompletedOnboardingUseCase();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasCompletedOnboarding ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Main White Card
                          Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tree Icon com fundo degradê
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/images/logo.png',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // App name
                                Text(
                                  'Run4Tree',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 10),

                                // Subtitle
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.5),
                                    children: [
                                      TextSpan(
                                        text: l10n.loginTaglineRunPrefix,
                                      ),
                                      TextSpan(
                                        text: l10n.loginTaglineTreesHighlight,
                                        style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: l10n.loginTaglineOffline),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Divisor com ícone
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade200,
                                        thickness: 1.5,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        Icons.eco_rounded,
                                        color: AppColors.primaryLight,
                                        size: 20,
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade200,
                                        thickness: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Feature rows
                                _buildFeatureRow(
                                  const Icon(
                                    Icons.wifi_off_rounded,
                                    size: 22,
                                    color: AppColors.primaryDark,
                                  ),
                                  l10n.loginFeatureOfflineTitle,
                                  l10n.loginFeatureOfflineSubtitle,
                                ),
                                const SizedBox(height: 14),
                                _buildFeatureRow(
                                  const Icon(
                                    Icons.lock_open_rounded,
                                    size: 22,
                                    color: AppColors.primaryDark,
                                  ),
                                  l10n.loginFeatureNoSignupTitle,
                                  l10n.loginFeatureNoSignupSubtitle,
                                ),
                                const SizedBox(height: 14),
                                _buildFeatureRow(
                                  const FaIcon(
                                    FontAwesomeIcons.tree,
                                    size: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                  l10n.loginFeaturePlantTreesTitle,
                                  l10n.loginFeaturePlantTreesSubtitle,
                                ),
                                const SizedBox(height: 36),

                                // Botão principal
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isCheckingOnboarding
                                        ? null
                                        : _handleStart,
                                    icon: _isCheckingOnboarding
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.directions_run_rounded,
                                            size: 22,
                                          ),
                                    label: Text(
                                      l10n.loginStartButton,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily:
                                            GoogleFonts.bebasNeue().fontFamily,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Bottom Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildChip(
                                context,
                                Icons.check_circle_outline_rounded,
                                l10n.loginChipSustainable,
                              ),
                              const SizedBox(width: 12),
                              _buildChip(
                                context,
                                Icons.bolt_rounded,
                                l10n.loginChipGamified,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(Widget icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
