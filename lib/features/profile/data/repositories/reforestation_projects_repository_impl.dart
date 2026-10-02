import 'package:flutter/foundation.dart';

import '../../../../core/services/tree_nation_projects_service.dart';
import '../../domain/entities/fundable_projects_result.dart';
import '../../domain/entities/reforestation_project_entity.dart';
import '../../domain/repositories/reforestation_projects_repository.dart';
import '../project_social_impact.dart';

/// Lê o catálogo público da Tree-Nation e devolve só o que o Run4Tree
/// consegue bancar com receita de anúncio.
class ReforestationProjectsRepositoryImpl
    implements ReforestationProjectsRepository {
  /// Teto de preço por árvore (EUR). É o mesmo patamar da espécie que a
  /// Cloud Function planta hoje (`TREE_NATION_SPECIES_ID=3657`, €0.35) e é o
  /// que define quais projetos entram na lista.
  static const double maxTreePriceEur = 0.35;

  final TreeNationProjectsService _service;

  /// Cache de processo: a lista muda de mês em mês, não de minuto em minuto,
  /// e a tela pode ser aberta e fechada várias vezes na mesma sessão.
  static FundableProjectsResult? _cache;

  ReforestationProjectsRepositoryImpl({TreeNationProjectsService? service})
    : _service = service ?? TreeNationProjectsService();

  @visibleForTesting
  static void clearCache() => _cache = null;

  @override
  Future<FundableProjectsResult> getFundableProjects() async {
    final cached = _cache;
    if (cached != null && cached.isLive) return cached;

    try {
      final dtos = await _service.fetchProjects();
      final projects =
          dtos
              .where((dto) => dto.isActive)
              .where((dto) {
                final price = dto.speciesPriceFrom;
                return price != null && price > 0 && price <= maxTreePriceEur;
              })
              .map(_toEntity)
              .toList()
            ..sort((a, b) {
              final byPrice = a.priceFromEur.compareTo(b.priceFromEur);
              return byPrice != 0 ? byPrice : a.name.compareTo(b.name);
            });

      if (projects.isEmpty) {
        // A API respondeu, mas nada cabe no teto — não é o que a tela quer
        // explicar, então vale mais mostrar a lista conhecida.
        debugPrint(
          'ReforestationProjects: nenhum projeto <= €$maxTreePriceEur '
          'em ${dtos.length} projetos; usando a cópia local',
        );
        return _fallback();
      }

      final result = FundableProjectsResult(projects: projects, isLive: true);
      _cache = result;
      return result;
    } on TreeNationProjectsException catch (e) {
      debugPrint('ReforestationProjects: $e; usando a cópia local');
      return _fallback();
    }
  }

  FundableProjectsResult _fallback() {
    final cached = _cache;
    if (cached != null) return cached;
    return FundableProjectsResult(
      projects: bundledFundableProjects,
      isLive: false,
    );
  }

  /// Junta o que veio vivo da API com a camada social curada do projeto.
  ReforestationProjectEntity _toEntity(TreeNationProjectDto dto) {
    final social = projectSocialImpacts[dto.id];
    return ReforestationProjectEntity(
      id: dto.id,
      name: dto.name,
      description: dto.description.trim(),
      countryCode: dto.location,
      imageUrl: dto.imageUrl,
      projectUrl: dto.url,
      priceFromEur: dto.speciesPriceFrom ?? maxTreePriceEur,
      latitude: dto.latitude,
      longitude: dto.longitude,
      socialImpacts: social?.impacts ?? const [],
      peopleImpact: social?.peopleImpact ?? '',
    );
  }
}

const String _imageHost =
    'https://treenation-uploads.s3.eu-central-1.amazonaws.com';

/// Cópia da resposta de `GET /api/projects` conferida em 19/09/2026, usada
/// quando o app está offline, já com a camada social costurada por cima. São
/// os projetos ativos a €0.35 — a mesma faixa em que a Cloud Function planta.
final List<ReforestationProjectEntity> bundledFundableProjects = [
  for (final project in _bundledCatalogue)
    if (projectSocialImpacts[project.id] case final social?)
      project.withSocialImpact(
        impacts: social.impacts,
        peopleImpact: social.peopleImpact,
      )
    else
      project,
];

const List<ReforestationProjectEntity> _bundledCatalogue = [
  ReforestationProjectEntity(
    id: 32,
    name: 'Save the Aberdare Forest',
    description:
        'Our project aims to restore the degraded Aberdare Forest by addressing the '
        'impacts of illegal logging, charcoal burning, and encroachment. To reverse '
        'this damage, we are planting indigenous tree species and supporting local '
        'communities with improved cookstoves and biogas units. These efforts not only '
        'restore the ecosystem but also enhance community resilience to climate change.',
    countryCode: 'KE',
    imageUrl: '$_imageHost/project-af9b3e59e5a6f32111059444370d061a.jpg',
    projectUrl: 'https://tree-nation.com/projects/save-the-aberdare-forest',
    priceFromEur: 0.35,
    latitude: -0.39104,
    longitude: 36.730492,
  ),
  ReforestationProjectEntity(
    id: 269,
    name: 'Replanting the burnt Mkussu Forest',
    description:
        'This project aims to restore the Mkussu Nature Forest Reserve, one of the nine '
        'forest reserves in Lushoto District, after it was damaged by fire. The project '
        'focuses on replanting indigenous tree species to rehabilitate the burnt areas, '
        'helping to revive this important ecosystem at Usambara Region located in '
        'Northern part of Tanzania.',
    countryCode: 'TZ',
    imageUrl: '$_imageHost/image-43e19dbc2d6361f7.png',
    projectUrl:
        'https://tree-nation.com/projects/replanting-the-burnt-mkussu-forest',
    priceFromEur: 0.35,
    latitude: -4.798667,
    longitude: 38.290218,
  ),
  ReforestationProjectEntity(
    id: 361,
    name: 'Plant to Stop Poverty',
    description:
        'Our project helps rural communities adopt agroforestry to combat poverty and '
        'the effects of climate change. This approach secures food and income while '
        'restoring and protecting forests through tree planting. With experience '
        'planting over 1,230,000 trees in different districts, we bring proven '
        'expertise to these initiatives.',
    countryCode: 'TZ',
    imageUrl: '$_imageHost/project-efa7732a9f5e5bdc2163ac00954b0ded.webp',
    projectUrl: 'https://tree-nation.com/projects/plant-to-stop-poverty',
    priceFromEur: 0.35,
    latitude: -5.148192,
    longitude: 38.448196,
  ),
  ReforestationProjectEntity(
    id: 716,
    name: 'Preservation of Mt. Elgon Ecosystem',
    description:
        'Our project works with over 54k local farmers in the Mount Elgon region to grow '
        'trees and build sustainable livelihoods. Uganda has lost at least 12% of its '
        'tree cover since 2001, threatening both the environment and local communities. '
        'By focusing on forest restoration and reducing the need for logging and '
        'unsustainable agriculture, we work to reverse this trend and protect the land '
        'for future generations.',
    countryCode: 'UG',
    imageUrl: '$_imageHost/project-b169d526289584f645570a6e1bda5c47.webp',
    projectUrl: 'https://tree-nation.com/projects/preservation-mt-elgon-uganda',
    priceFromEur: 0.35,
    latitude: 1.272721,
    longitude: 34.048634,
  ),
];
