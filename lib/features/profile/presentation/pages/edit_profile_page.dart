import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

/// Formulário para editar os dados coletados no questionário de boas-vindas.
///
/// Recebe o [ProfileController] já carregado pela [ProfilePage] para salvar
/// e recalcular as métricas com os mesmos usecases, sem duplicar a cadeia
/// datasource → repository → usecases.
class EditProfilePage extends StatefulWidget {
  final ProfileController controller;
  final ProfileEntity profile;

  const EditProfilePage({
    super.key,
    required this.controller,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _weeklyGoalController;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _ageController = TextEditingController(text: p.age.toString());
    _weightController = TextEditingController(text: _formatNumber(p.weightKg));
    _heightController = TextEditingController(text: _formatNumber(p.heightCm));
    _weeklyGoalController = TextEditingController(
      text: _formatNumber(p.weeklyGoalKm),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  bool get _isValid {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weeklyGoal = double.tryParse(
      _weeklyGoalController.text.replaceAll(',', '.'),
    );

    return name.isNotEmpty &&
        age != null &&
        age > 0 &&
        age < 120 &&
        weight != null &&
        weight > 0 &&
        height != null &&
        height > 0 &&
        weeklyGoal != null &&
        weeklyGoal > 0;
  }

  Future<void> _handleSave() async {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();

    final success = await widget.controller.updateProfile(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
      heightCm: double.parse(_heightController.text.replaceAll(',', '.')),
      weeklyGoalKm: double.parse(
        _weeklyGoalController.text.replaceAll(',', '.'),
      ),
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileEditButton,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            AppLocalizations.of(
                              context,
                            )!.editProfileNameFieldLabel,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _inputDecoration(
                            AppLocalizations.of(context)!.fieldLabelAge,
                            suffixText: AppLocalizations.of(
                              context,
                            )!.suffixYears,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  AppLocalizations.of(
                                    context,
                                  )!.fieldLabelWeight,
                                  suffixText: AppLocalizations.of(
                                    context,
                                  )!.suffixKg,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _heightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  AppLocalizations.of(
                                    context,
                                  )!.fieldLabelHeight,
                                  suffixText: AppLocalizations.of(
                                    context,
                                  )!.suffixCm,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _weeklyGoalController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            AppLocalizations.of(context)!.fieldLabelWeeklyGoal,
                            suffixText: AppLocalizations.of(context)!.suffixKm,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (widget.controller.hasSaveError) ...[
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.profileSaveErrorMessage,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isValid && !widget.controller.isSaving
                          ? _handleSave
                          : null,
                      child: widget.controller.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(
                                context,
                              )!.editProfileSaveButton,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
