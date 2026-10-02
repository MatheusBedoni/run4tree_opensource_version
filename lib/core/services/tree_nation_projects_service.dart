import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Catálogo público de projetos da Tree-Nation (`GET /api/projects`).
///
/// Diferente de `POST /api/plant` — que gasta dinheiro de verdade, exige o
/// token da conta e por isso só roda na Cloud Function — este endpoint é
/// somente-leitura e aberto, então o app pode chamá-lo direto para mostrar os
/// projetos reais sem nenhuma credencial embarcada.
class TreeNationProjectsService {
  static const String defaultBaseUrl = 'https://tree-nation.com';

  final String _baseUrl;
  final http.Client _client;
  final Duration _timeout;

  TreeNationProjectsService({
    String baseUrl = defaultBaseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client(),
       _timeout = timeout;

  /// Lista todos os projetos do catálogo, ativos e inativos.
  ///
  /// Lança [TreeNationProjectsException] em falha de rede, HTTP inesperado ou
  /// corpo ilegível — a resposta é um array JSON puro, sem envelope.
  Future<List<TreeNationProjectDto>> fetchProjects() async {
    final uri = Uri.parse('$_baseUrl/api/projects');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } catch (e) {
      debugPrint('TreeNationProjectsService: falha de rede em $uri -> $e');
      throw TreeNationProjectsException('falha de rede: $e');
    }

    if (response.statusCode != 200) {
      throw TreeNationProjectsException('HTTP ${response.statusCode}');
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw TreeNationProjectsException('corpo não-JSON: $e');
    }
    if (decoded is! List) {
      throw TreeNationProjectsException(
        'esperava uma lista, veio ${decoded.runtimeType}',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TreeNationProjectDto.fromJson)
        .where((project) => project.id > 0)
        .toList(growable: false);
  }

  void dispose() => _client.close();
}

/// Um item de `GET /api/projects`, com os campos tolerando ausência: a API
/// omite `image`, `description` e até `species_price_from` em alguns projetos.
class TreeNationProjectDto {
  final int id;
  final String name;
  final String description;

  /// ISO-3166 alpha-2 — a API chama de `location`.
  final String location;

  final String imageUrl;
  final String url;

  /// `species_price_from` em EUR; `null` quando o projeto não vende árvore
  /// avulsa (ex: só pacotes de crédito de carbono).
  final double? speciesPriceFrom;

  /// `active` ou `inactive`: só os ativos aceitam plantio novo.
  final String status;

  final double latitude;
  final double longitude;

  const TreeNationProjectDto({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.url,
    required this.speciesPriceFrom,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  bool get isActive => status == 'active';

  factory TreeNationProjectDto.fromJson(Map<String, dynamic> json) {
    return TreeNationProjectDto(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      location: _asString(json['location']),
      imageUrl: _asString(json['image']),
      url: _asString(json['url']),
      speciesPriceFrom: _asDoubleOrNull(json['species_price_from']),
      status: _asString(json['status']),
      latitude: _asDoubleOrNull(json['lat']) ?? 0,
      longitude: _asDoubleOrNull(json['long']) ?? 0,
    );
  }
}

class TreeNationProjectsException implements Exception {
  final String message;

  const TreeNationProjectsException(this.message);

  @override
  String toString() => 'TreeNationProjectsException: $message';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _asString(dynamic value) => value is String ? value : '';
