import 'social_impact.dart';

/// Um projeto de reflorestamento real da Tree-Nation que o Run4Tree consegue
/// financiar — isto é, cujo preço por árvore cabe no valor que os anúncios
/// geram (a faixa de €0.35).
///
/// Entidade pura: nada de JSON aqui. O mapeamento da API fica no
/// `TreeNationProjectsService`.
class ReforestationProjectEntity {
  /// Id do projeto na Tree-Nation (ex: 269 = Mkussu Forest).
  final int id;

  final String name;

  /// Descrição oficial escrita pelo próprio planter, como aparece no site.
  final String description;

  /// País no formato ISO-3166 alpha-2 (ex: `TZ`), como a API devolve.
  final String countryCode;

  /// Foto oficial do projeto; pode vir vazia quando a API não tem imagem.
  final String imageUrl;

  /// Página pública do projeto no site da Tree-Nation.
  final String projectUrl;

  /// Menor preço (EUR) de uma árvore nesse projeto — o número que decide se
  /// o projeto cabe no orçamento gerado pelos anúncios.
  final double priceFromEur;

  final double latitude;
  final double longitude;

  /// Selos sociais do projeto. Vazio quando o projeto entrou no catálogo
  /// depois da última curadoria — a tela simplesmente omite a linha.
  final List<SocialImpact> socialImpacts;

  /// Uma frase concreta sobre as pessoas do projeto (empregos, viveiros,
  /// mudas distribuídas), tirada da página oficial. Vazia quando não há.
  final String peopleImpact;

  const ReforestationProjectEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.countryCode,
    required this.imageUrl,
    required this.projectUrl,
    required this.priceFromEur,
    required this.latitude,
    required this.longitude,
    this.socialImpacts = const [],
    this.peopleImpact = '',
  });

  bool get hasSocialImpact =>
      socialImpacts.isNotEmpty || peopleImpact.isNotEmpty;

  /// Mesmo projeto, com a camada social preenchida. Existe porque os dados do
  /// catálogo e os selos sociais vêm de fontes diferentes (API x curadoria).
  ReforestationProjectEntity withSocialImpact({
    required List<SocialImpact> impacts,
    required String peopleImpact,
  }) {
    return ReforestationProjectEntity(
      id: id,
      name: name,
      description: description,
      countryCode: countryCode,
      imageUrl: imageUrl,
      projectUrl: projectUrl,
      priceFromEur: priceFromEur,
      latitude: latitude,
      longitude: longitude,
      socialImpacts: impacts,
      peopleImpact: peopleImpact,
    );
  }
}
