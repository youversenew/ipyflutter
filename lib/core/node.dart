import 'dart:collection';

/// Represents a single node in the UI Tree.
/// This is the data model that Renderers consume.
class UINode {
  final String id;
  final String type;
  final Map<String, dynamic> props;
  final List<UINode> children;

  const UINode({
    required this.id,
    required this.type,
    this.props = const {},
    this.children = const [],
  });

  /// Factory to parse JSON tree from Python
  factory UINode.fromJson(Map<String, dynamic> json) {
    return UINode(
      id: json['id']?.toString() ?? 'unknown',
      type: json['type']?.toString() ?? 'container',
      props:
          json['props'] != null ? Map<String, dynamic>.from(json['props']) : {},
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => UINode.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  /// Helper to find a node by ID in the subtree (for partial updates)
  UINode? find(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.find(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Creates a copy with replaced properties (for patching)
  UINode copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? props,
    List<UINode>? children,
  }) {
    return UINode(
      id: id ?? this.id,
      type: type ?? this.type,
      props: props ?? this.props,
      children: children ?? this.children,
    );
  }

  @override
  String toString() =>
      'UINode(id: $id, type: $type, children: ${children.length})';
}
