import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/usecases/save_user_profile_usecase.dart';
import '../controllers/onboarding_controller.dart';

/// Questionário de boas-vindas exibido apenas para novos usuários.
///
/// Coleta nome, idade, peso, altura e meta semanal de km em um fluxo
/// step-by-step, salvando tudo localmente ao final para que o app possa
/// acompanhar a evolução do usuário e personalizar suas métricas.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingController _controller;
  late final PageController _pageController;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weeklyGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(
      SaveUserProfileUseCase(UserProfileRepositoryImpl()),
    );
    _pageController = PageController();
    _controller.addListener(_syncPage);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPage);
    _controller.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  void _syncPage() {
    final target = _controller.currentStep;
    if (_pageController.hasClients &&
        (_pageController.page?.round() ?? 0) != target) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handlePrimaryButton() async {
    if (!_controller.canAdvance) return;
    FocusScope.of(context).unfocus();

    if (!_controller.isLastStep) {
      _controller.nextStep();
      return;
    }

    final success = await _controller.submit();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_controller.currentStep > 0) {
          _controller.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildProgressBar(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNameStep(),
                        _buildAgeStep(),
                        _buildBodyStep(),
                        _buildGoalStep(),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _controller.currentStep > 0
                ? _controller.previousStep
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textPrimary,
          ),
          const Spacer(),
          Text(
            '${_controller.currentStep + 1}/${OnboardingController.stepCount}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        (_controller.currentStep + 1) / OnboardingController.stepCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: AppColors.progressTrack,
          valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
        ),
      ),
    );
  }

  Widget _buildStepScaffold({
    required Widget icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffixText}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
    );
  }

  Widget _buildNameStep() {
    return _buildStepScaffold(
      icon: const FaIcon(
        FontAwesomeIcons.user,
        color: AppColors.primaryDark,
        size: 28,
      ),
      title: AppLocalizations.of(context)!.onboardingNameTitle,
      subtitle: AppLocalizations.of(context)!.onboardingNameSubtitle,
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        decoration: _inputDecoration(
          AppLocalizations.of(context)!.onboardingNameFieldLabel,
        ),
        onChanged: _controller.updateName,
        onSubmitted: (_) => _handlePrimaryButton(),
      ),
    );
  }

  Widget _buildAgeStep() {
    return _buildStepScaffold(
      icon: const FaIcon(
        FontAwesomeIcons.cakeCandles,
        color: AppColors.primaryDark,
        size: 28,
      ),
      title: AppLocalizations.of(context)!.onboardingAgeTitle,
      subtitle: AppLocalizations.of(context)!.onboardingAgeSubtitle,
      child: TextField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecoration(
          AppLocalizations.of(context)!.fieldLabelAge,
          suffixText: AppLocalizations.of(context)!.suffixYears,
        ),
        onChanged: _controller.updateAge,
        onSubmitted: (_) => _handlePrimaryButton(),
      ),
    );
  }

  Widget _buildBodyStep() {
    return _buildStepScaffold(
      icon: const FaIcon(
        FontAwesomeIcons.rulerVertical,
        color: AppColors.primaryDark,
        size: 28,
      ),
      title: AppLocalizations.of(context)!.onboardingBodyTitle,
      subtitle: AppLocalizations.of(context)!.onboardingBodySubtitle,
      child: Column(
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              AppLocalizations.of(context)!.fieldLabelWeight,
              suffixText: AppLocalizations.of(context)!.suffixKg,
            ),
            onChanged: _controller.updateWeight,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              AppLocalizations.of(context)!.fieldLabelHeight,
              suffixText: AppLocalizations.of(context)!.suffixCm,
            ),
            onChanged: _controller.updateHeight,
            onSubmitted: (_) => _handlePrimaryButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return _buildStepScaffold(
      icon: const FaIcon(
        FontAwesomeIcons.flagCheckered,
        color: AppColors.primaryDark,
        size: 28,
      ),
      title: AppLocalizations.of(context)!.onboardingGoalTitle,
      subtitle: AppLocalizations.of(context)!.onboardingGoalSubtitle,
      child: TextField(
        controller: _weeklyGoalController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _inputDecoration(
          AppLocalizations.of(context)!.fieldLabelWeeklyGoal,
          suffixText: AppLocalizations.of(context)!.suffixKm,
        ),
        onChanged: _controller.updateWeeklyGoal,
        onSubmitted: (_) => _handlePrimaryButton(),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.hasError) ...[
            Text(
              AppLocalizations.of(context)!.onboardingSaveErrorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.canAdvance && !_controller.isSaving
                  ? _handlePrimaryButton
                  : null,
              child: _controller.isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _controller.isLastStep
                          ? AppLocalizations.of(context)!.onboardingFinishButton
                          : AppLocalizations.of(
                              context,
                            )!.onboardingContinueButton,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
