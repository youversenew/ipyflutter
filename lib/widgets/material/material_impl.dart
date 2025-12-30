import 'package:flutter/material.dart';
import '../../core/node.dart';
import '../../core/transport.dart';
import '../base_widget.dart';
import '../registry.dart';
import 'styles.dart';

// ==========================================
// 1. Layout Widgets (Container, Row, Col, Stack)
// ==========================================

class MatContainer implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Container(
      width: (node.props['width'] as num?)?.toDouble(),
      height: (node.props['height'] as num?)?.toDouble(),
      margin: MaterialStyleParser.parsePadding(node.props['margin']),
      padding: MaterialStyleParser.parsePadding(node.props['padding']),
      alignment: node.props['alignment'] == 'center' ? Alignment.center : null,
      decoration: BoxDecoration(
        color: MaterialStyleParser.parseColor(node.props['bg_color']),
        borderRadius: BorderRadius.circular(
            (node.props['radius'] as num?)?.toDouble() ?? 0),
        border: node.props['border_color'] != null
            ? Border.all(
                color:
                    MaterialStyleParser.parseColor(node.props['border_color'])!,
                width: (node.props['border_width'] as num?)?.toDouble() ?? 1.0)
            : null,
        boxShadow: node.props['shadow'] == true
            ? [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ]
            : [],
      ),
      child: node.children.isNotEmpty
          ? WidgetRegistry.build(node.children.first, transport)
          : null,
    );
  }
}

class MatRow implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Row(
      mainAxisAlignment:
          MaterialStyleParser.parseMainAlign(node.props['align']),
      crossAxisAlignment:
          MaterialStyleParser.parseCrossAlign(node.props['cross_align']),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class MatColumn implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Column(
      mainAxisAlignment:
          MaterialStyleParser.parseMainAlign(node.props['align']),
      crossAxisAlignment:
          MaterialStyleParser.parseCrossAlign(node.props['cross_align']),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class MatStack implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Stack(
      alignment: node.props['align'] == 'center'
          ? Alignment.center
          : Alignment.topLeft,
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

// ==========================================
// 2. Basic Widgets (Text, Icon, Image, Spacer)
// ==========================================

class MatText implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Text(
      node.props['value']?.toString() ?? "",
      textAlign:
          node.props['align'] == 'center' ? TextAlign.center : TextAlign.start,
      style: MaterialStyleParser.parseTextStyle(node.props),
    );
  }
}

class MatIcon implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    // Basic mapping, requires a full map for production
    IconData icon = Icons.help;
    if (node.props['icon'] == 'home') icon = Icons.home;
    if (node.props['icon'] == 'settings') icon = Icons.settings;
    if (node.props['icon'] == 'person') icon = Icons.person;
    if (node.props['icon'] == 'add') icon = Icons.add;

    return Icon(
      icon,
      size: (node.props['size'] as num?)?.toDouble(),
      color: MaterialStyleParser.parseColor(node.props['color']),
    );
  }
}

class MatImage implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    final src = node.props['src'] as String?;
    if (src == null) return Icon(Icons.broken_image);

    if (src.startsWith("http")) {
      return Image.network(
        src,
        width: (node.props['width'] as num?)?.toDouble(),
        height: (node.props['height'] as num?)?.toDouble(),
        fit: BoxFit.cover,
      );
    } else {
      // For local assets or binary streams handled later
      return Image.asset(src);
    }
  }
}

class MatSpacer implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Spacer(flex: (node.props['flex'] as num?)?.toInt() ?? 1);
  }
}

// ==========================================
// 3. Interactive Widgets (Buttons)
// ==========================================

class MatButton implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: MaterialStyleParser.parseColor(node.props['bg_color']),
      foregroundColor: MaterialStyleParser.parseColor(node.props['color']),
      elevation: (node.props['elevation'] as num?)?.toDouble(),
    );

    final VoidCallback? onPressed = node.props.containsKey('on_click')
        ? () => transport.sendEvent(node.id, "click", null)
        : null;

    return ElevatedButton(
      style: style,
      onPressed: onPressed,
      child: Text(node.props['text'] ?? "Button"),
    );
  }
}

class MatFAB implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return FloatingActionButton(
      backgroundColor: MaterialStyleParser.parseColor(node.props['bg_color']),
      onPressed: () => transport.sendEvent(node.id, "click", null),
      child: Icon(Icons.add), // Helper needed to map icon name
    );
  }
}

// ==========================================
// 4. Input Widgets (Stateful Wrappers)
// ==========================================

class MatInput implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return _MatInputStateful(node: node, transport: transport);
  }
}

class _MatInputStateful extends StatefulWidget {
  final UINode node;
  final TransportService transport;
  const _MatInputStateful({required this.node, required this.transport});

  @override
  State<_MatInputStateful> createState() => _MatInputStatefulState();
}

class _MatInputStatefulState extends State<_MatInputStateful> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.props['value']);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      obscureText: widget.node.props['password'] == true,
      decoration: InputDecoration(
        labelText: widget.node.props['label'],
        hintText: widget.node.props['placeholder'],
        border: OutlineInputBorder(),
        filled: widget.node.props['filled'] == true,
      ),
      onChanged: (v) {
        if (widget.node.props.containsKey('on_change')) {
          widget.transport.sendEvent(widget.node.id, "change", v);
        }
      },
      onSubmitted: (v) {
        if (widget.node.props.containsKey('on_submit')) {
          widget.transport.sendEvent(widget.node.id, "submit", v);
        }
      },
    );
  }
}

class MatCheckbox implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Checkbox(
      value: node.props['value'] == true,
      activeColor: MaterialStyleParser.parseColor(node.props['active_color']),
      onChanged: (val) => transport.sendEvent(node.id, "change", val),
    );
  }
}

class MatSwitch implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Switch(
      value: node.props['value'] == true,
      activeColor: MaterialStyleParser.parseColor(node.props['active_color']),
      onChanged: (val) => transport.sendEvent(node.id, "change", val),
    );
  }
}

// ==========================================
// 5. List & Structure Widgets
// ==========================================

class MatListView implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return ListView(
      padding: MaterialStyleParser.parsePadding(node.props['padding']),
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class MatListTile implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return ListTile(
      leading: node.props['icon'] != null ? Icon(Icons.info) : null, // Simplify
      title: Text(node.props['title'] ?? ""),
      subtitle:
          node.props['subtitle'] != null ? Text(node.props['subtitle']) : null,
      onTap: () => transport.sendEvent(node.id, "click", null),
    );
  }
}

class MatCard implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return Card(
      elevation: (node.props['elevation'] as num?)?.toDouble(),
      color: MaterialStyleParser.parseColor(node.props['bg_color']),
      margin: MaterialStyleParser.parsePadding(node.props['margin']),
      child: Padding(
        padding: MaterialStyleParser.parsePadding(node.props['padding'] ?? 10),
        child: node.children.isNotEmpty
            ? WidgetRegistry.build(node.children.first, transport)
            : null,
      ),
    );
  }
}
