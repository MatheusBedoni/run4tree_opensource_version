import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:run_4_tree/core/services/tree_nation_projects_service.dart';
import 'package:run_4_tree/features/profile/data/project_social_impact.dart';
import 'package:run_4_tree/features/profile/data/repositories/reforestation_projects_repository_impl.dart';
import 'package:run_4_tree/features/profile/domain/entities/social_impact.dart';

/// Recorte real de `GET /api/projects` (conferido em 19/09/2026): um projeto
/// barato e ativo, um barato mas inativo e um ativo caro demais.
const _projectsJson = [
  {
    'description': 'Restore the Mkussu Nature Forest Reserve after a fire.',
    'id': 269,
    'image': 'https://example.test/mkussu.png',
    'lat': -4.798667,
    'location': 'TZ',
    'long': 38.290218,
    'name': 'Replanting the burnt Mkussu Forest',
    'slug': 'replanting-the-burnt-mkussu-forest',
    'species_price_from': 0.35,
    'status': 'active',
    'url':
        'https://tree-nation.com/projects/replanting-the-burnt-mkussu-forest',
  },
  {
    'description': 'Kenya mangroves.',
    'id': 821,
    'lat': -4.0,
    'location': 'KE',
    'long': 39.6,
    'name': 'Kenya Mangroves Restoration',
    'species_price_from': 0.35,
    'status': 'inactive',
    'url': 'https://tree-nation.com/projects/kenya-mangroves-restoration',
  },
  {
    'description': 'Aberdare.',
    'id': 32,
    'image': 'https://example.test/aberdare.jpg',
    'lat': -0.39104,
    'location': 'KE',
    'long': 36.730492,
    'name': 'Save the Aberdare Forest',
    'species_price_from': 0.2,
    'status': 'active',
    'url': 'https://tree-nation.com/projects/save-the-aberdare-forest',
  },
  {
    'description': 'Caro demais para o orçamento de um anúncio.',
    'id': 7,
    'lat': 12.0,
    'location': 'NI',
    'long': -85.0,
    'name': 'CommuniTree',
    'species_price_from': 13,
    'status': 'active',
    'url': 'https://tree-nation.com/projects/communitree',
  },
];

TreeNationProjectsService _serviceReturning(Object body, {int status = 200}) {
  return TreeNationProjectsService(
    client: MockClient(
      (_) async => http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

void main() {
  setUp(ReforestationProjectsRepositoryImpl.clearCache);

  group('TreeNationProjectsService', () {
    test('mapeia a lista e tolera campos ausentes', () async {
      final projects = await _serviceReturning(_projectsJson).fetchProjects();

      expect(projects, hasLength(4));
      final mkussu = projects.first;
      expect(mkussu.id, 269);
      expect(mkussu.location, 'TZ');
      expect(mkussu.speciesPriceFrom, 0.35);
      expect(mkussu.isActive, isTrue);
      // O projeto 821 vem sem `image` na API.
      expect(projects[1].imageUrl, '');
      expect(projects[1].isActive, isFalse);
    });

    test('lança quando a API responde HTTP de erro', () {
      final service = _serviceReturning('{}', status: 503);

      expect(
        service.fetchProjects(),
        throwsA(isA<TreeNationProjectsException>()),
      );
    });

    test('lança quando o corpo não é uma lista', () {
      final service = _serviceReturning({'status': 'error'});

      expect(
        service.fetchProjects(),
        throwsA(isA<TreeNationProjectsException>()),
      );
    });
  });

  group('camada social dos projetos', () {
    test('todo projeto da cópia local chega com o lado social preenchido', () {
      expect(bundledFundableProjects, isNotEmpty);
      for (final project in bundledFundableProjects) {
        expect(
          project.hasSocialImpact,
          isTrue,
          reason: '${project.name} (#${project.id}) sem impacto social',
        );
        expect(project.peopleImpact, isNotEmpty, reason: project.name);
        expect(project.socialImpacts, isNotEmpty, reason: project.name);
      }
    });

    test('a curadoria cobre exatamente os projetos da cópia local', () {
      expect(
        projectSocialImpacts.keys.toSet(),
        bundledFundableProjects.map((p) => p.id).toSet(),
      );
    });
  });

  group('ReforestationProjectsRepositoryImpl', () {
    test('fica só com os ativos que cabem em €0.35, do mais barato', () async {
      final repository = ReforestationProjectsRepositoryImpl(
        service: _serviceReturning(_projectsJson),
      );

      final result = await repository.getFundableProjects();

      expect(result.isLive, isTrue);
      expect(result.projects.map((p) => p.id), [32, 269]);
      expect(result.projects.first.priceFromEur, 0.2);
      expect(result.projects.last.countryCode, 'TZ');
      expect(
        result.projects.last.projectUrl,
        'https://tree-nation.com/projects/replanting-the-burnt-mkussu-forest',
      );
    });

    test('cai para a cópia local quando a Tree-Nation não responde', () async {
      final repository = ReforestationProjectsRepositoryImpl(
        service: TreeNationProjectsService(
          client: MockClient((_) async => throw const SocketExceptionStub()),
        ),
      );

      final result = await repository.getFundableProjects();

      expect(result.isLive, isFalse);
      expect(result.projects, same(bundledFundableProjects));
      expect(
        result.projects.every(
          (p) =>
              p.priceFromEur <=
              ReforestationProjectsRepositoryImpl.maxTreePriceEur,
        ),
        isTrue,
      );
    });

    test('costura a camada social nos projetos vindos da API', () async {
      final repository = ReforestationProjectsRepositoryImpl(
        service: _serviceReturning(_projectsJson),
      );

      final result = await repository.getFundableProjects();
      final mkussu = result.projects.firstWhere((p) => p.id == 269);

      expect(mkussu.hasSocialImpact, isTrue);
      expect(mkussu.socialImpacts, contains(SocialImpact.womenLeadership));
      expect(mkussu.peopleImpact, contains('14 of them women'));
    });

    test('projeto fora da curadoria fica sem linha social', () async {
      final desconhecido = {
        ..._projectsJson.first,
        'id': 999999,
        'name': 'Projeto novo no catálogo',
      };
      final repository = ReforestationProjectsRepositoryImpl(
        service: _serviceReturning([desconhecido]),
      );

      final result = await repository.getFundableProjects();

      expect(result.projects.single.hasSocialImpact, isFalse);
      expect(result.projects.single.socialImpacts, isEmpty);
      expect(result.projects.single.peopleImpact, isEmpty);
    });

    test('cai para a cópia local quando nada cabe no teto de preço', () async {
      final repository = ReforestationProjectsRepositoryImpl(
        service: _serviceReturning([_projectsJson.last]),
      );

      final result = await repository.getFundableProjects();

      expect(result.isLive, isFalse);
      expect(result.projects, same(bundledFundableProjects));
    });
  });
}

/// Falha de rede qualquer: o service só precisa ver uma exceção no `get`.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
