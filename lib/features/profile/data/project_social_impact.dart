import '../domain/entities/social_impact.dart';

/// O lado social de cada projeto, curado à mão a partir da página oficial da
/// Tree-Nation (seção "benefits" + updates do planter), conferido em
/// 19/09/2026.
///
/// Por que curado e não vindo da API: `GET /api/projects` só devolve nome,
/// país, preço, foto e descrição. Os selos sociais e os números de emprego
/// existem no site, mas não em nenhum endpoint público — então eles vivem
/// aqui, com a fonte anotada, e a tela só mostra o que está confirmado.
class ProjectSocialImpact {
  final List<SocialImpact> impacts;

  /// Uma frase verificável sobre as pessoas — nada de estimativa nossa.
  final String peopleImpact;

  const ProjectSocialImpact({
    required this.impacts,
    required this.peopleImpact,
  });
}

/// Chaveado pelo id do projeto na Tree-Nation. Projeto novo no catálogo cai
/// fora do mapa e aparece sem a linha social, em vez de ganhar um texto
/// genérico que ninguém conferiu.
const Map<int, ProjectSocialImpact> projectSocialImpacts = {
  // tree-nation.com/projects/save-the-aberdare-forest
  32: ProjectSocialImpact(
    impacts: [
      SocialImpact.localJobs,
      SocialImpact.womenLeadership,
      SocialImpact.education,
      SocialImpact.foodSecurity,
    ],
    peopleImpact:
        'The forest was being cut for charcoal, so the project gives the '
        'families around it improved cookstoves and biogas units — cooking '
        'dinner stops depending on cutting the forest down.',
  ),
  // tree-nation.com/projects/replanting-the-burnt-mkussu-forest
  269: ProjectSocialImpact(
    impacts: [
      SocialImpact.localJobs,
      SocialImpact.womenLeadership,
      SocialImpact.education,
      SocialImpact.inclusion,
    ],
    peopleImpact:
        'Three nurseries employ 22 monthly-paid workers — 14 of them women, '
        'several single mothers — to raise the native seedlings, and the '
        'coastal site at Mwamboza village is putting 500,000 mangroves into '
        'the ground.',
  ),
  // tree-nation.com/projects/plant-to-stop-poverty
  361: ProjectSocialImpact(
    impacts: [
      SocialImpact.foodSecurity,
      SocialImpact.localJobs,
      SocialImpact.water,
      SocialImpact.education,
    ],
    peopleImpact:
        'Over 1,230,000 trees planted with the village environment '
        'committees. Agroforestry puts food and income on the same plot, and '
        'restoring the water sources eases the friction between villagers and '
        'the forest reserve.',
  ),
  // tree-nation.com/projects/preservation-mt-elgon-uganda
  716: ProjectSocialImpact(
    impacts: [
      SocialImpact.localJobs,
      SocialImpact.womenLeadership,
      SocialImpact.foodSecurity,
      SocialImpact.education,
    ],
    peopleImpact:
        '116 people are directly employed — nursery operators, data clerks, '
        'community facilitators — across 39 nurseries that give over 3 '
        'million seedlings a year, free, to smallholder farmers, families, '
        'churches and schools. Women-run nurseries keep growing in number.',
  ),
};
