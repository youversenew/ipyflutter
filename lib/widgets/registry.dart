import 'package:flutter/material.dart';
import '../core/node.dart';
import '../core/transport.dart';
import 'base_widget.dart';
import 'cupertino/cupertino_impl.dart';
import 'material/material_impl.dart';
import 'custom/custom_impl.dart';

class WidgetRegistry {
  static final Map<String, IpyWidgetRenderer> _renderers = {};

  static void init() {
    // Layout
    register("container", MatContainer());
    register("row", MatRow());
    register("column", MatColumn());
    register("stack", MatStack());
    register("spacer", MatSpacer());

    // Basic
    register("text", MatText());
    register("icon", MatIcon());
    register("image", MatImage());

    // Interactive
    register("button", MatButton());
    register("fab", MatFAB());
    // ... inside WidgetRegistry.init()

    // Primitives
    register("center", CustomCenter());
    register("padding", CustomPadding());
    register("sized_box", CustomSizedBox());
    register("spacer", CustomSpacer());
    register("expanded", CustomExpanded());

    // Advanced Layouts
    register("wrap", CustomWrap());
    register("stack", CustomStack());

    // Scrolls
    register("custom_list", CustomListView());
    register("custom_grid", CustomGridView());
    register("scroll_view", CustomSingleChildScrollView());

    // Visuals
    register("opacity", CustomOpacity());
    register("clip_rrect", CustomClipRRect());
    register("visibility", CustomVisibility());

    // Interaction
    register("gesture", CustomGestureDetector());
    // Input
    register("input", MatInput());
    register("checkbox", MatCheckbox());
    register("switch", MatSwitch());

    // List & Structure
    register("listview", MatListView());
    register("list_tile", MatListTile());
    register("card", MatCard());
    // Add this to your WidgetRegistry.init()

// Cupertino Layout
    register("cup_scaffold", CupScaffold());
    register("cup_list_section", CupListSection());
    register("cup_list_tile", CupListTile());

    // Cupertino Interactive
    register("cup_button", CupButton());
    register("cup_switch", CupSwitch());
    register("cup_slider", CupSlider());
    register("cup_segmented", CupSegmentedControl());

    // Cupertino Inputs
    register("cup_input", CupInput());
    register("cup_search", CupSearchField());

    // Cupertino Visuals
    register("cup_spinner", CupActivityIndicator());
    register("cup_icon", CupIcon());
  }

  static void register(String type, IpyWidgetRenderer renderer) {
    _renderers[type] = renderer;
  }

  static Widget build(UINode node, TransportService transport) {
    final renderer = _renderers[node.type];
    if (renderer == null) {
      return Container(
        padding: EdgeInsets.all(8),
        color: Colors.red.withOpacity(0.2),
        child:
            Text("Unknown: ${node.type}", style: TextStyle(color: Colors.red)),
      );
    }
    return renderer.render(node, transport);
  }
}
