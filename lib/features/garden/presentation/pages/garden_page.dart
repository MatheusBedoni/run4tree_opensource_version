import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/tree_garden_repository_impl.dart';
import '../../domain/entities/planted_tree_entity.dart';
import '../../domain/entities/tree_progress_entity.dart';
import '../../data/services/planting_orders_sync.dart';
import '../../domain/entities/pending_tree_entity.dart';
import '../../domain/usecases/get_pending_trees_usecase.dart';
import '../../domain/usecases/get_planted_trees_usecase.dart';
import '../../domain/usecases/get_tree_progress_usecase.dart';
import '../controllers/garden_controller.dart';

/// GardenPage — mostra a floresta real do usuário (árvores plantadas via
/// Tree-Nation, financiadas pelos anúncios assistidos) e o progresso rumo
/// à próxima árvore.
class GardenPage extends StatefulWidget {
  const GardenPage({super.key});

  @override
  State<GardenPage> createState() => GardenPageState();
}

class GardenPageState extends State<GardenPage> {
  late final GardenController _controller;

  @override
  void initState() {
    super.initState();
    final repository = TreeGardenRepositoryImpl();
    _controller = GardenController(
      GetTreeProgressUseCase(repository),
      GetPlantedTreesUseCase(repository),
      GetPendingTreesUseCase(repository),
    );
    _controller.loadProgress();
    // Quando o certificado de uma árvore "a caminho" chega, a floresta
    // atualiza sozinha.
    PlantingOrdersSync.instance.completed.addListener(_onOrderCompleted);
  }

  void _onOrderCompleted() => _controller.loadProgress();

  /// Recarrega o progresso — chamado pela Home quando o usuário navega até
  /// essa aba, já que ela vive dentro de um `IndexedStack` e não seria
  /// reconstruída sozinha depois de uma corrida.
  Future<void> refresh() => _controller.loadProgress();

  @override
  void dispose() {
    PlantingOrdersSync.instance.completed.removeListener(_onOrderCompleted);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.progress == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final progress = _controller.progress;
            final treesPlanted = progress?.treesPlanted ?? 0;
            final progressPercent = progress?.progressPercent ?? 0.0;
            final seedsAccumulated = progress?.seedsAccumulated ?? 0;
            const seedsPerTree = TreeProgressEntity.seedsPerTree;
            final plantedTrees = _controller.plantedTrees;
            final co2CompensatedKg = _controller.co2CompensatedKg;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.gardenTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.gardenSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildImpactCard(treesPlanted, co2CompensatedKg),
                  const SizedBox(height: 20),
                  _buildProgressCard(
                    seedsAccumulated: seedsAccumulated,
                    seedsPerTree: seedsPerTree,
                    progressPercent: progressPercent,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppLocalizations.of(context)!.gardenForestTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildForestGrid(plantedTrees, _controller.pendingTrees),
                  if (_controller.error != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorBanner(_messageFor(context)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _messageFor(BuildContext context) {
    return AppLocalizations.of(context)!.gardenLoadErrorMessage;
  }

  /// Card de destaque com as duas métricas de maior impacto: total de
  /// árvores plantadas e CO2 (kg) compensado por elas.
  Widget _buildImpactCard(int treesPlanted, double co2CompensatedKg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.progressGreen,

        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildImpactStat(
              icon: FontAwesomeIcons.tree,
              value: '$treesPlanted',
              label: AppLocalizations.of(
                context,
              )!.gardenTreesPlanted(treesPlanted),
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildImpactStat(
              icon: FontAwesomeIcons.leaf,
              value: AppLocalizations.of(
                context,
              )!.gardenCo2CompensatedValue(co2CompensatedKg.toStringAsFixed(2)),
              label: AppLocalizations.of(context)!.gardenCo2CompensatedLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat({
    required FaIconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required int seedsAccumulated,
    required int seedsPerTree,
    required double progressPercent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.gardenNextTreeLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.seedling,
                    size: 14,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.gardenSeedsProgress(seedsAccumulated, seedsPerTree),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.progressGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestGrid(
    List<PlantedTreeEntity> plantedTrees,
    List<PendingTreeEntity> pendingTrees,
  ) {
    if (plantedTrees.isEmpty && pendingTrees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const FaIcon(
              FontAwesomeIcons.seedling,
              size: 28,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.gardenForestEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // As árvores a caminho vêm primeiro: são as mais recentes e as que o
    // usuário está esperando.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingTrees.length + plantedTrees.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => index < pendingTrees.length
          ? _buildPendingTreeCard(pendingTrees[index])
          : _buildTreeCard(plantedTrees[index - pendingTrees.length]),
    );
  }

  /// Árvore conquistada, com o plantio a caminho: sem certificado ainda.
  Widget _buildPendingTreeCard(PendingTreeEntity tree) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentOrange.withValues(alpha: 0.15),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.seedling,
                color: AppColors.accentOrange,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.gardenPendingTreeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.gardenPendingTreeBody(tree.treeNumber),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.hourglassHalf,
                size: 11,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.gardenPendingTreeStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCard(PlantedTreeEntity tree) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.progressTrack,
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.tree,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tree.speciesName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tree.country,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openCertificate(tree.certificateUrl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.certificate,
                  size: 12,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.gardenViewCertificate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCertificate(String url) async {
    final uri = Uri.tryParse(url);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.gardenCertificateOpenError,
          ),
        ),
      );
    }
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
