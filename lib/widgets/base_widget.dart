import 'package:flutter/widgets.dart';
import '../core/node.dart';
import '../core/transport.dart';

/// The strict contract that all IPYUI Widget Renderers must implement.
///
/// This Strategy Pattern allows the `WidgetRegistry` to dynamically
/// pick the correct visual representation for a node without knowing
/// the implementation details.
abstract class IpyWidgetRenderer {
  /// Converts a data-driven [UINode] into a specific Flutter [Widget].
  ///
  /// * [node]: Contains the `props` (styles, data) and `children` from Python.
  /// * [transport]: The channel to send user events (clicks, inputs) back to Python.
  Widget render(UINode node, TransportService transport);
}
