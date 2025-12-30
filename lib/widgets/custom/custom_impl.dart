import 'package:flutter/material.dart';
import '../../core/node.dart';
import '../../core/transport.dart';
import '../base_widget.dart';
import '../registry.dart';

// Helper for parsing Generic Colors/Styles locally
class _CustomStyle {
  static Color? parseColor(String? hex) {
    if (hex == null) return null;
    if (hex == "transparent") return Colors.transparent;
    if (hex == "black") return Colors.black;
    if (hex == "white") return Colors.white;
    try {
      String clean = hex.replaceAll("#", "");
      if (clean.length == 6) clean = "FF$clean";
      return Color(int.parse(clean, radix: 16));
    } catch (e) {
      return null;
    }
  }

  static EdgeInsets parsePadding(dynamic val) {
    if (val is int || val is double) return EdgeInsets.all(val.toDouble());
    if (val is List) {
      return EdgeInsets.fromLTRB(
          (val[0] as num).toDouble(),
          (val[1] as num).toDouble(),
          (val[2] as num).toDouble(),
          (val[3] as num).toDouble());
    }
    return EdgeInsets.zero;
  }
}

// ==========================================
// 1. Layout Primitives (Center, Padding, SizedBox)
// ==========================================

class CustomCenter implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Center(
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : null,
    );
  }
}

class CustomPadding implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Padding(
      padding: _CustomStyle.parsePadding(node.props['padding']),
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : null,
    );
  }
}

class CustomSizedBox implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return SizedBox(
      width: (node.props['width'] as num?)?.toDouble(),
      height: (node.props['height'] as num?)?.toDouble(),
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : null,
    );
  }
}

class CustomSpacer implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Spacer(
      flex: (node.props['flex'] as num?)?.toInt() ?? 1,
    );
  }
}

class CustomExpanded implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Expanded(
      flex: (node.props['flex'] as num?)?.toInt() ?? 1,
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : SizedBox(),
    );
  }
}

// ==========================================
// 2. Advanced Layouts (Wrap, Grid, Stack)
// ==========================================

class CustomWrap implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Wrap(
      direction: node.props['direction'] == 'vertical'
          ? Axis.vertical
          : Axis.horizontal,
      spacing: (node.props['spacing'] as num?)?.toDouble() ?? 0.0,
      runSpacing: (node.props['run_spacing'] as num?)?.toDouble() ?? 0.0,
      alignment: _parseWrapAlign(node.props['align']),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }

  WrapAlignment _parseWrapAlign(String? val) {
    switch (val) {
      case 'center':
        return WrapAlignment.center;
      case 'end':
        return WrapAlignment.end;
      case 'space_between':
        return WrapAlignment.spaceBetween;
      default:
        return WrapAlignment.start;
    }
  }
}

class CustomStack implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Stack(
      alignment: _parseStackAlign(node.props['align']),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }

  AlignmentGeometry _parseStackAlign(String? val) {
    switch (val) {
      case 'center':
        return Alignment.center;
      case 'top_right':
        return Alignment.topRight;
      case 'bottom_right':
        return Alignment.bottomRight;
      case 'bottom_left':
        return Alignment.bottomLeft;
      default:
        return Alignment.topLeft;
    }
  }
}

// ==========================================
// 3. Scrollable Views (ListView, GridView, ScrollView)
// ==========================================

class CustomListView implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    final bool isHorizontal = node.props['direction'] == 'horizontal';

    return ListView(
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      padding: _CustomStyle.parsePadding(node.props['padding']),
      reverse: node.props['reverse'] == true,
      shrinkWrap: node.props['shrink'] == true,
      physics: node.props['physics'] == 'bouncing'
          ? BouncingScrollPhysics()
          : AlwaysScrollableScrollPhysics(),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class CustomGridView implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    final int cols = (node.props['cols'] as num?)?.toInt() ?? 2;
    final double spacing = (node.props['spacing'] as num?)?.toDouble() ?? 10.0;
    final double ratio = (node.props['child_ratio'] as num?)?.toDouble() ?? 1.0;

    return GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: ratio,
      padding: _CustomStyle.parsePadding(node.props['padding']),
      shrinkWrap: node.props['shrink'] == true,
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class CustomSingleChildScrollView implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return SingleChildScrollView(
      scrollDirection: node.props['direction'] == 'horizontal'
          ? Axis.horizontal
          : Axis.vertical,
      padding: _CustomStyle.parsePadding(node.props['padding']),
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : null,
    );
  }
}

// ==========================================
// 4. Visual Effects (Opacity, ClipRRect, Transform)
// ==========================================

class CustomOpacity implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Opacity(
      opacity: (node.props['value'] as num?)?.toDouble() ?? 1.0,
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : SizedBox(),
    );
  }
}

class CustomClipRRect implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
          (node.props['radius'] as num?)?.toDouble() ?? 0),
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : SizedBox(),
    );
  }
}

class CustomVisibility implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Visibility(
      visible: node.props['visible'] != false, // Defaults to true
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : SizedBox(),
    );
  }
}

// ==========================================
// 5. Interaction (GestureDetector)
// ==========================================

class CustomGestureDetector implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return GestureDetector(
      onTap: () {
        if (node.props.containsKey('on_click')) {
          transport.sendEvent(node.id, "click", null);
        }
      },
      onLongPress: () {
        if (node.props.containsKey('on_long_press')) {
          transport.sendEvent(node.id, "long_press", null);
        }
      },
      onDoubleTap: () {
        if (node.props.containsKey('on_double_tap')) {
          transport.sendEvent(node.id, "double_tap", null);
        }
      },
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : Container(color: Colors.transparent), // Ensure hit test works
    );
  }
}
