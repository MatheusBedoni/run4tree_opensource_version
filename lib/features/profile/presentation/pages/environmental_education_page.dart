import 'package:flutter/material.dart';
import 'package:run_4_tree/core/theme/app_colors.dart';
import 'package:run_4_tree/l10n/generated/app_localizations.dart';

class EnvironmentalEducationPage extends StatelessWidget {
  const EnvironmentalEducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.educationPageTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context: context,
              icon: Icons.park_rounded,
              title: l10n.educationForestsTitle,
              body: l10n.educationForestsBody,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 32),
            _buildSection(
              context: context,
              icon: Icons.thermostat_rounded,
              title: l10n.educationGlobalWarmingTitle,
              body: l10n.educationGlobalWarmingBody,
              color: AppColors.accentOrange,
            ),
            const SizedBox(height: 32),
            _buildSection(
              context: context,
              icon: Icons.cloud_rounded,
              title: l10n.educationCo2Title,
              body: l10n.educationCo2Body,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
