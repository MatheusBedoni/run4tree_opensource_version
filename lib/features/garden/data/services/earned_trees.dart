import 'dart:async';

/// Uma árvore pessoal que acabou de ser conquistada.
class EarnedTree {
  /// Pedido de plantio = item do feed. `null` só no caminho antigo, sem pedido.
  final String? orderId;
  final int treeNumber;

  /// `false` quando o plantio ficou "a caminho".
  final bool isPlanted;
  final String speciesName;
  final String country;

  const EarnedTree({
    required this.orderId,
    required this.treeNumber,
    required this.isPlanted,
    this.speciesName = '',
    this.country = '',
  });
}

/// Avisa a tela de quem está ouvindo (a home) que uma árvore foi conquistada,
/// para mostrar os parabéns na hora certa.
class EarnedTrees {
  EarnedTrees._();

  static final EarnedTrees instance = EarnedTrees._();

  final StreamController<EarnedTree> _controller =
      StreamController<EarnedTree>.broadcast();

  Stream<EarnedTree> get stream => _controller.stream;

  void add(EarnedTree tree) => _controller.add(tree);
}
