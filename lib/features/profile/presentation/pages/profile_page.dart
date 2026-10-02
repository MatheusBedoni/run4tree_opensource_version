import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:run_4_tree/core/theme/app_colors.dart';
import 'package:run_4_tree/l10n/generated/app_localizations.dart';
import 'package:run_4_tree/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:run_4_tree/features/profile/domain/entities/profile_entity.dart';
import 'package:run_4_tree/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:run_4_tree/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:run_4_tree/features/profile/presentation/controllers/profile_controller.dart';
import 'package:run_4_tree/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:run_4_tree/features/profile/presentation/pages/how_we_plant_trees_page.dart';
import 'package:run_4_tree/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:run_4_tree/features/profile/presentation/pages/terms_of_service_page.dart';
import 'package:run_4_tree/features/profile/presentation/pages/environmental_education_page.dart';
import 'package:run_4_tree/features/stickers/presentation/controllers/sticker_controller.dart';
import 'package:run_4_tree/features/stickers/presentation/controllers/sticker_controller_factory.dart';
import 'package:run_4_tree/features/stickers/presentation/pages/sticker_collection_page.dart';
import 'package:run_4_tree/features/stickers/presentation/widgets/sticker_avatar.dart';
import 'package:run_4_tree/features/global_forest/data/services/feed_preferences.dart';

class ProfilePage extends StatefulWidget {
  /// Controller da coleção de adesivos. A [HomePage] passa o dela para que a
  /// troca de avatar aqui atualize o marcador do mapa na hora; quando ausente,
  /// a página cria o seu.
  final StickerController? stickerController;

  const ProfilePage({super.key, this.stickerController});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FeedPreferences _feedPreferences = FeedPreferences();
  bool _feedUpdates = false;

  late final ProfileController _controller;
  late final StickerController _stickerController;

  /// Só descarta o controller de adesivos se ele nasceu aqui.
  late final bool _ownsStickerController;

  @override
  void initState() {
    super.initState();
    _feedPreferences.feedUpdatesEnabled().then((enabled) {
      if (mounted) setState(() => _feedUpdates = enabled);
    });
    final repository = ProfileRepositoryImpl();
    _controller = ProfileController(
      GetProfileUseCase(repository),
      UpdateProfileUseCase(repository),
    );
    _controller.loadProfile();

    _ownsStickerController = widget.stickerController == null;
    _stickerController = widget.stickerController ?? createStickerController();
    if (_ownsStickerController) {
      _stickerController.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsStickerController) _stickerController.dispose();
    super.dispose();
  }

  Future<void> _openStickerCollection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StickerCollectionPage(controller: _stickerController),
      ),
    );
  }

  Future<void> _openEditProfile(ProfileEntity profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfilePage(controller: _controller, profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            );
          }

          if (_controller.hasLoadError && _controller.profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.profileLoadErrorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _controller.loadProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.commonRetryButton,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = _controller.profile;
          if (profile == null) return const SizedBox();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.profileAgeMemberSince(
                      profile.age,
                      _formatMonthYear(profile.memberSince),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openEditProfile(profile),
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.profileEditButton,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primaryLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildStickersSection(),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildLegalSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Avatar do usuário: o adesivo escolhido na coleção. Tocar abre a galeria
  /// para trocar (ou ver o que ainda falta desbloquear).
  Widget _buildAvatar() {
    return ListenableBuilder(
      listenable: _stickerController,
      builder: (context, _) {
        final selected = _stickerController.selectedSticker;
        return Column(
          children: [
            GestureDetector(
              onTap: _openStickerCollection,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  StickerAvatar(assetPath: selected?.assetPath, size: 96),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.profileAvatarChangeHint,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  /// Atalho para a coleção, com prévia dos adesivos já conquistados.
  Widget _buildStickersSection() {
    return ListenableBuilder(
      listenable: _stickerController,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final unlocked = _stickerController.stickers
            .where((sticker) => sticker.isUnlocked)
            .toList();
        final preview = unlocked.take(5).toList();
        final remaining = unlocked.length - preview.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                l10n.profileStickersSectionTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _openStickerCollection,
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.solidStar,
                            size: 18,
                            color: AppColors.accentOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.profileStickersCardTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.profileStickersCardSubtitle(
                                    unlocked.length,
                                    _stickerController.totalCount,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (final sticker in preview)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: StickerAvatar(
                                  assetPath: sticker.assetPath,
                                  size: 40,
                                  borderWidth: 2,
                                  showShadow: false,
                                ),
                              ),
                            if (remaining > 0)
                              Text(
                                '+$remaining',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(ProfileEntity profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: FaIcon(
              FontAwesomeIcons.tree,
              color: AppColors.primaryLight,
              size: 22,
            ),
            value: '${profile.treesPlanted}',
            label: AppLocalizations.of(context)!.profileTreesLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icon(Icons.route_rounded, color: AppColors.skyBlue, size: 24),
            value: profile.totalDistanceKm.toStringAsFixed(1),
            label: AppLocalizations.of(context)!.profileTotalKmLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icon(
              Icons.directions_run_rounded,
              color: AppColors.accentOrange,
              size: 24,
            ),
            value: '${profile.totalRuns}',
            label: AppLocalizations.of(context)!.profileRunsLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Widget icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoCard(ProfileEntity profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.profileBodyDataTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBodyInfoItem(
                AppLocalizations.of(context)!.fieldLabelWeight,
                '${profile.weightKg.toStringAsFixed(1)} ${AppLocalizations.of(context)!.suffixKg}',
              ),
              _buildBodyInfoDivider(),
              _buildBodyInfoItem(
                AppLocalizations.of(context)!.fieldLabelHeight,
                '${profile.heightCm.toStringAsFixed(0)} ${AppLocalizations.of(context)!.suffixCm}',
              ),
              _buildBodyInfoDivider(),
              _buildBodyInfoItem(
                AppLocalizations.of(context)!.profileBmiLabel,
                profile.bmi.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoDivider() {
    return Container(width: 1, height: 36, color: AppColors.background);
  }

  /// Opt-in do push "Novidades do feed" (ver docs/global_feed.md).
  Widget _buildNotificationsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: _feedUpdates,
        activeTrackColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        secondary: const FaIcon(
          FontAwesomeIcons.earthAmericas,
          size: 18,
          color: AppColors.primaryDark,
        ),
        title: Text(
          l10n.feedUpdatesOptInTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          l10n.feedUpdatesOptInBody,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        onChanged: (enabled) {
          setState(() => _feedUpdates = enabled);
          _feedPreferences.setFeedUpdates(enabled);
        },
      ),
    );
  }

  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.profileLegalSectionTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildLegalRow(
                  icon: Icons.eco_rounded,
                  label: AppLocalizations.of(
                    context,
                  )!.profileHowWePlantTreesButton,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HowWePlantTreesPage(),
                    ),
                  ),
                ),
                _buildLegalDivider(),
                _buildLegalRow(
                  icon: Icons.school_rounded,
                  label: AppLocalizations.of(
                    context,
                  )!.profileEnvironmentalEducationButton,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EnvironmentalEducationPage(),
                    ),
                  ),
                ),
                _buildLegalDivider(),
                _buildLegalRow(
                  icon: Icons.description_outlined,
                  label: AppLocalizations.of(context)!.profileTermsButton,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServicePage(),
                    ),
                  ),
                ),
                _buildLegalDivider(),
                _buildLegalRow(
                  icon: Icons.privacy_tip_outlined,
                  label: AppLocalizations.of(context)!.profilePrivacyButton,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  ),
                ),
                _buildLegalDivider(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.background,
    );
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat(
      'MMM/y',
      Localizations.localeOf(context).toString(),
    ).format(date);
  }
}
