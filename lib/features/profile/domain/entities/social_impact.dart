/// O que um projeto de reflorestamento muda na vida de quem mora ali.
///
/// A Tree-Nation publica esses selos na página de cada projeto ("benefits"),
/// mas não os expõe na API pública — por isso eles são curados no app, a
/// partir da página oficial do projeto. Ver `project_social_impact.dart`.
enum SocialImpact {
  /// Emprego pago para gente da região (viveiro, plantio, monitoramento).
  localJobs('Local jobs'),

  /// Trabalho e liderança de mulheres dentro do projeto.
  womenLeadership('Women\'s work'),

  /// Educação ambiental e escolas.
  education('Schools'),

  /// Comida e renda saindo da mesma terra (agrofloresta, fruteiras).
  foodSecurity('Food & income'),

  /// Água: nascentes, rios e a redução de disputa por eles.
  water('Water'),

  /// Inclusão de grupos marginalizados.
  inclusion('Inclusion');

  final String label;

  const SocialImpact(this.label);
}
