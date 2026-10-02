import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../garden/data/repositories/tree_garden_repository_impl.dart';
import '../../../garden/domain/usecases/get_pending_trees_usecase.dart';
import '../../../garden/domain/usecases/get_planted_trees_usecase.dart';
import '../../../garden/domain/usecases/get_tree_progress_usecase.dart';
import '../../../garden/presentation/controllers/garden_controller.dart';
import '../../data/repositories/reforestation_projects_repository_impl.dart';
import '../../domain/entities/reforestation_project_entity.dart';
import '../../domain/entities/social_impact.dart';
import '../../domain/usecases/get_fundable_projects_usecase.dart';
import '../controllers/fundable_projects_controller.dart';

/// Explica de forma transparente como o mecanismo "assista anúncio -> planta
/// árvore" funciona de verdade, com os números reais do usuário (não texto
/// genérico) — reaproveita o mesmo [GardenController] da GardenPage — e lista
/// os projetos reais da Tree-Nation que cabem no preço de uma árvore,
/// buscados ao vivo no catálogo público deles.
class HowWePlantTreesPage extends StatefulWidget {
  const HowWePlantTreesPage({super.key});

  @override
  State<HowWePlantTreesPage> createState() => _HowWePlantTreesPageState();
}

class _HowWePlantTreesPageState extends State<HowWePlantTreesPage> {
  late final GardenController _controller;
  late final FundableProjectsController _projectsController;

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

    _projectsController = FundableProjectsController(
      GetFundableProjectsUseCase(ReforestationProjectsRepositoryImpl()),
    );
    _projectsController.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _projectsController.dispose();
    super.dispose();
  }

  Future<void> _openTreeNation() => _openUrl('https://tree-nation.com');

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'How We Plant Real Trees',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final treesPlanted = _controller.progress?.treesPlanted ?? 0;
            final co2Kg = _controller.co2CompensatedKg;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLiveStatsCard(treesPlanted, co2Kg),
                  const SizedBox(height: 24),
                  _section(
                    'No fake points — real trees',
                    'Most apps show you a progress bar that goes nowhere. In Run4Tree, once your progress bar fills '
                        'up, the App places a real, paid order for a tree with Tree-Nation, an independent reforestation '
                        'platform. You can open your Garden tab any time to see every tree you\'ve funded, along with '
                        'its species, country, and a certificate link.',
                  ),
                  _section(
                    'The ads are the funding, not a paywall',
                    'Run4Tree has no subscription and no in-app purchase. Every time you watch a short rewarded ad in '
                        'the Garden tab, the real revenue that ad generates is credited toward the cost of a tree. Once '
                        'enough ad-funded value has accumulated, we place the order — nothing to buy, nothing to unlock.',
                  ),
                  _section(
                    'Verified server-side, so it can\'t be faked',
                    'We use RevenueCat to confirm — on Google\'s own servers, not just on your phone — that an ad was '
                        'genuinely watched to completion before any value is credited. This anti-fraud check protects '
                        'the integrity of every tree planted through the App.',
                  ),
                  const _PeaceCard(),
                  const SizedBox(height: 24),
                  _section(
                    'One tree costs €0.35 — these are the projects it pays for',
                    'A tree is not an abstract number here: it is a seedling that a local team puts in the ground for '
                        '€0.35. That price is only possible because these planters grow their own seedlings and hire '
                        'from the villages around the forest, and it is exactly what makes an ad-funded app able to '
                        'plant anything at all. The projects below are read live from Tree-Nation\'s public catalogue '
                        'every time you open this screen: they are the active projects running at that price today — '
                        'the ones a tree paid for by your ads can actually reach. Each one carries the social '
                        'commitments it publishes on Tree-Nation.',
                  ),
                  _buildProjectsSection(),
                  const SizedBox(height: 20),
                  _section(
                    'Our reforestation partner',
                    'Tree-Nation plants and tracks real trees around the world and issues a certificate for each one. '
                        'Run4Tree places real orders with them using an anonymous device ID — never your name or any '
                        'personal information.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openTreeNation,
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowUpRightFromSquare,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                    label: const Text(
                      'Visit Tree-Nation',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      side: const BorderSide(color: AppColors.primaryLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveStatsCard(int treesPlanted, double co2Kg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.progressGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              FontAwesomeIcons.tree,
              '$treesPlanted',
              treesPlanted == 1
                  ? 'tree planted by you'
                  : 'trees planted by you',
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _stat(
              FontAwesomeIcons.leaf,
              '${co2Kg.toStringAsFixed(2)} kg',
              'CO2 compensated',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(FaIconData icon, String value, String label) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
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

  Widget _section(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de projetos reais, com aviso quando o app não conseguiu falar com
  /// a Tree-Nation e está mostrando a cópia local.
  Widget _buildProjectsSection() {
    return ListenableBuilder(
      listenable: _projectsController,
      builder: (context, _) {
        if (_projectsController.isLoading &&
            _projectsController.projects.isEmpty) {
          return const _ProjectsLoading();
        }

        final projects = _projectsController.projects;
        if (projects.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_projectsController.isLive) const _OfflineProjectsNotice(),
            for (final project in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ProjectCard(
                  project: project,
                  onOpen: () => _openUrl(project.projectUrl),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// O argumento social da tela: por que plantar árvore é, antes de tudo, uma
/// história sobre as pessoas que moram naquela terra. Vem em destaque porque
/// é a parte que o resto do app (CO2, contador, medalhas) não conta.
class _PeaceCard extends StatelessWidget {
  const _PeaceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.handshakeAngle,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trees are the cheap part. People are the point.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Nobody burns a forest for fun. In the regions we fund, wood is cut because charcoal pays today and '
            'the soil stopped feeding anyone years ago — and once the land and the water go, families move and '
            'neighbours start competing over what is left. Restoration only holds when a standing tree is worth '
            'more to a village than a cut one.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'So the €0.35 does not only buy a seedling. It pays the nursery worker who raised it, the farmer whose '
            'land hosts it, and the training that keeps it alive through the first dry season. That is the quiet '
            'part of this app: someone watching a 30-second ad after a run puts wages in the hands of a woman '
            'filling seedling tubes in Lushoto this month.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsLoading extends StatelessWidget {
  const _ProjectsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.progressTrack),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primaryLight,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Loading projects from Tree-Nation…',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OfflineProjectsNotice extends StatelessWidget {
  const _OfflineProjectsNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 13,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'We couldn\'t reach Tree-Nation right now, so these are the '
              'projects we last confirmed. Open any of them to see the live page.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ReforestationProjectEntity project;
  final VoidCallback onOpen;

  const _ProjectCard({required this.project, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.progressTrack),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProjectImage(url: project.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(
                      '${_flagEmoji(project.countryCode)} '
                              '${_countryName(project.countryCode)}'
                          .trim(),
                    ),
                    _chip(
                      '€${project.priceFromEur.toStringAsFixed(2)} per tree',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (project.hasSocialImpact) ...[
                  const SizedBox(height: 14),
                  _SocialImpactBlock(project: project),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const FaIcon(
                FontAwesomeIcons.arrowUpRightFromSquare,
                size: 12,
                color: AppColors.primaryDark,
              ),
              label: const Text(
                'See this project on Tree-Nation',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// "O que isso muda para as pessoas": a frase verificada na página oficial do
/// projeto mais os selos sociais que ele publica.
class _SocialImpactBlock extends StatelessWidget {
  final ReforestationProjectEntity project;

  const _SocialImpactBlock({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.peopleGroup,
                size: 12,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'What it changes for people',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          if (project.peopleImpact.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.peopleImpact,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (project.socialImpacts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final impact in project.socialImpacts)
                  _SocialImpactChip(impact: impact),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialImpactChip extends StatelessWidget {
  final SocialImpact impact;

  const _SocialImpactChip({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(_iconFor(impact), size: 10, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            impact.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  static FaIconData _iconFor(SocialImpact impact) {
    switch (impact) {
      case SocialImpact.localJobs:
        return FontAwesomeIcons.briefcase;
      case SocialImpact.womenLeadership:
        return FontAwesomeIcons.venus;
      case SocialImpact.education:
        return FontAwesomeIcons.graduationCap;
      case SocialImpact.foodSecurity:
        return FontAwesomeIcons.bowlFood;
      case SocialImpact.water:
        return FontAwesomeIcons.droplet;
      case SocialImpact.inclusion:
        return FontAwesomeIcons.handsHoldingChild;
    }
  }
}

/// Foto oficial do projeto; cai para um bloco verde com uma árvore quando a
/// imagem não carrega (offline, URL vazia ou 404 no bucket deles).
class _ProjectImage extends StatelessWidget {
  final String url;

  const _ProjectImage({required this.url});

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ProjectImageFallback(height: _height);

    return Image.network(
      url,
      height: _height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const _ProjectImageFallback(height: _height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: _height,
          width: double.infinity,
          color: AppColors.progressTrack,
        );
      },
    );
  }
}

class _ProjectImageFallback extends StatelessWidget {
  final double height;

  const _ProjectImageFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.mapGrass,
      alignment: Alignment.center,
      child: const FaIcon(
        FontAwesomeIcons.tree,
        size: 30,
        color: AppColors.primaryDark,
      ),
    );
  }
}

/// Converte o código ISO-3166 alpha-2 da Tree-Nation na bandeira equivalente
/// (par de "regional indicator symbols"). Código estranho vira string vazia.
String _flagEmoji(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (code.length != 2) return '';
  const base = 0x1F1E6; // 🇦
  final first = code.codeUnitAt(0) - 0x41;
  final second = code.codeUnitAt(1) - 0x41;
  if (first < 0 || first > 25 || second < 0 || second > 25) return '';
  return String.fromCharCodes([base + first, base + second]);
}

/// Nomes dos países onde a Tree-Nation tem projetos. Um país novo no catálogo
/// cai no próprio código, que ainda é legível na tela.
String _countryName(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  const names = {
    'AR': 'Argentina',
    'AU': 'Australia',
    'BF': 'Burkina Faso',
    'BO': 'Bolivia',
    'BR': 'Brazil',
    'CA': 'Canada',
    'CD': 'DR Congo',
    'CL': 'Chile',
    'CM': 'Cameroon',
    'CO': 'Colombia',
    'ES': 'Spain',
    'FR': 'France',
    'GB': 'United Kingdom',
    'GN': 'Guinea',
    'ID': 'Indonesia',
    'IE': 'Ireland',
    'IN': 'India',
    'KE': 'Kenya',
    'KH': 'Cambodia',
    'MG': 'Madagascar',
    'MX': 'Mexico',
    'MZ': 'Mozambique',
    'NE': 'Niger',
    'NG': 'Nigeria',
    'NI': 'Nicaragua',
    'NP': 'Nepal',
    'PE': 'Peru',
    'PT': 'Portugal',
    'RO': 'Romania',
    'SN': 'Senegal',
    'TH': 'Thailand',
    'TZ': 'Tanzania',
    'UG': 'Uganda',
    'US': 'United States',
    'ZW': 'Zimbabwe',
  };
  return names[code] ?? code;
}
