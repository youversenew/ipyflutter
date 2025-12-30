import 'package:flutter/cupertino.dart';
import '../../core/node.dart';
import '../../core/transport.dart';
import '../base_widget.dart';
import '../registry.dart';
import 'cup_styles.dart';
import 'icons_map.dart';

// ==========================================
// 1. Structure & Layout (Scaffold, Nav)
// ==========================================

class CupScaffold implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    // Finds the first child as body, second as navigation bar if exists
    Widget? body;
    ObstructingPreferredSizeWidget? navBar;

    if (node.children.isNotEmpty) {
      body = WidgetRegistry.build(node.children.first, transport);
    }

    if (node.props['title'] != null) {
      navBar = CupertinoNavigationBar(
        middle: Text(node.props['title']),
        backgroundColor: node.props['nav_color'] != null
            ? CupStyleParser.parseColor(node.props['nav_color'])
            : null,
      );
    }

    return CupertinoPageScaffold(
      navigationBar: navBar,
      backgroundColor:
          CupStyleParser.parseColor(node.props['bg_color'] ?? "white"),
      child: SafeArea(child: body ?? Container()),
    );
  }
}

class CupListSection implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupertinoListSection.insetGrouped(
      header: node.props['header'] != null ? Text(node.props['header']) : null,
      children:
          node.children.map((c) => WidgetRegistry.build(c, transport)).toList(),
    );
  }
}

class CupListTile implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupertinoListTile(
      leading: CupIconHelper.getIcon(node.props['icon'],
          color: CupertinoColors.systemBlue),
      title: Text(node.props['title'] ?? ""),
      subtitle:
          node.props['subtitle'] != null ? Text(node.props['subtitle']) : null,
      trailing: node.props['trailing_text'] != null
          ? Text(node.props['trailing_text'],
              style: TextStyle(color: CupertinoColors.systemGrey))
          : const CupertinoListTileChevron(),
      onTap: () => transport.sendEvent(node.id, "click", null),
    );
  }
}

// ==========================================
// 2. Interactive (Button, Switch, Slider)
// ==========================================

class CupButton implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    final bool isFilled = node.props['filled'] == true;

    return CupertinoButton(
      color: isFilled
          ? CupStyleParser.parseColor(node.props['bg_color'] ?? 'blue')
          : null,
      padding: CupStyleParser.parsePadding(node.props['padding'] ?? 16),
      onPressed: () => transport.sendEvent(node.id, "click", null),
      child: Text(
        node.props['text'] ?? "Button",
        style: TextStyle(
          color: isFilled
              ? CupertinoColors.white
              : CupStyleParser.parseColor(node.props['color'] ?? 'blue'),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CupSwitch implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupertinoSwitch(
      value: node.props['value'] == true,
      activeColor:
          CupStyleParser.parseColor(node.props['active_color'] ?? 'green'),
      onChanged: (val) => transport.sendEvent(node.id, "change", val),
    );
  }
}

class CupSlider implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return SizedBox(
      width: (node.props['width'] as num?)?.toDouble(),
      child: CupertinoSlider(
        value: (node.props['value'] as num?)?.toDouble() ?? 0.0,
        min: (node.props['min'] as num?)?.toDouble() ?? 0.0,
        max: (node.props['max'] as num?)?.toDouble() ?? 100.0,
        activeColor:
            CupStyleParser.parseColor(node.props['active_color'] ?? 'blue'),
        onChanged: (val) {
          // Send event (maybe debounce this in full implementation)
          transport.sendEvent(node.id, "change", val);
        },
      ),
    );
  }
}

class CupSegmentedControl implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    // Expects props['children'] as Map<String, String> for keys/labels
    // Simplified here to assume list of strings in 'items' prop
    final List<dynamic> items = node.props['items'] ?? ["A", "B"];
    final Map<int, Widget> map = {};
    for (int i = 0; i < items.length; i++) {
      map[i] = Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(items[i].toString()),
      );
    }

    return CupertinoSlidingSegmentedControl<int>(
      children: map,
      groupValue: (node.props['value'] as num?)?.toInt() ?? 0,
      onValueChanged: (val) {
        transport.sendEvent(node.id, "change", val);
      },
    );
  }
}

// ==========================================
// 3. Inputs (TextField, Search)
// ==========================================

class CupInput implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return _CupInputStateful(node: node, transport: transport);
  }
}

class _CupInputStateful extends StatefulWidget {
  final UINode node;
  final TransportService transport;
  const _CupInputStateful({required this.node, required this.transport});

  @override
  State<_CupInputStateful> createState() => _CupInputStatefulState();
}

class _CupInputStatefulState extends State<_CupInputStateful> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.props['value']);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _ctrl,
      placeholder: widget.node.props['placeholder'],
      obscureText: widget.node.props['password'] == true,
      padding: EdgeInsets.all(12),
      prefix: widget.node.props['icon'] != null
          ? Padding(
              padding: EdgeInsets.only(left: 8),
              child: CupIconHelper.getIcon(widget.node.props['icon'],
                  size: 20, color: CupertinoColors.systemGrey))
          : null,
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

class CupSearchField implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupertinoSearchTextField(
      placeholder: node.props['placeholder'] ?? 'Search',
      onChanged: (val) => transport.sendEvent(node.id, "change", val),
      onSubmitted: (val) => transport.sendEvent(node.id, "submit", val),
    );
  }
}

// ==========================================
// 4. Feedback & Display (Indicator, Icon)
// ==========================================

class CupActivityIndicator implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupertinoActivityIndicator(
      radius: (node.props['size'] as num?)?.toDouble() ?? 10.0,
      color: CupStyleParser.parseColor(node.props['color']),
    );
  }
}

class CupIcon implements IpyWidgetRenderer {
  @override
  Widget render(UINode node, TransportService transport) {
    return CupIconHelper.getIcon(
      node.props['icon'],
      size: (node.props['size'] as num?)?.toDouble() ?? 24,
      color: CupStyleParser.parseColor(node.props['color']),
    );
  }
}
