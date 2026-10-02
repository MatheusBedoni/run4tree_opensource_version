/// Árvore pessoal já conquistada, com o plantio a caminho: o pedido existe no
/// servidor e o certificado chega quando a Tree-Nation (ou o admin) plantar.
class PendingTreeEntity {
  final String orderId;
  final int treeNumber;
  final DateTime createdAt;

  const PendingTreeEntity({
    required this.orderId,
    required this.treeNumber,
    required this.createdAt,
  });
}
