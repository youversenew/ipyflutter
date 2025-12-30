class UINode {
  final String id;
  final String type;
  final Map<String, dynamic> props;
  final List<UINode> children;

  UINode(
      {required this.id,
      required this.type,
      this.props = const {},
      this.children = const []});

  factory UINode.fromJson(Map<String, dynamic> json) {
    return UINode(
      id: json['id'] ?? 'unknown',
      type: json['type'] ?? 'container',
      props: json['props'] ?? {},
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => UINode.fromJson(c))
          .toList(),
    );
  }
}
