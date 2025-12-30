import 'package:flutter/material.dart';

class MaterialStyleParser {
  static Color? parseColor(String? hex) {
    if (hex == null) return null;
    switch (hex) {
      case "white":
        return Colors.white;
      case "black":
        return Colors.black;
      case "blue":
        return Colors.blue;
      case "red":
        return Colors.red;
      case "green":
        return Colors.green;
      case "grey":
        return Colors.grey;
      case "transparent":
        return Colors.transparent;
      default:
        try {
          // Handle #RRGGBB or #AARRGGBB
          String clean = hex.replaceAll("#", "");
          if (clean.length == 6) clean = "FF$clean";
          return Color(int.parse(clean, radix: 16));
        } catch (e) {
          return null;
        }
    }
  }

  static EdgeInsets parsePadding(dynamic val) {
    if (val is int || val is double) return EdgeInsets.all(val.toDouble());
    if (val is List) {
      // [left, top, right, bottom]
      return EdgeInsets.fromLTRB(
          (val[0] as num).toDouble(),
          (val[1] as num).toDouble(),
          (val[2] as num).toDouble(),
          (val[3] as num).toDouble());
    }
    return EdgeInsets.zero;
  }

  static MainAxisAlignment parseMainAlign(String? val) {
    switch (val) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment parseCrossAlign(String? val) {
    switch (val) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  static TextStyle parseTextStyle(Map<String, dynamic> props) {
    return TextStyle(
      fontSize: (props['size'] as num?)?.toDouble() ?? 14,
      color: parseColor(props['color']),
      fontWeight: props['bold'] == true ? FontWeight.bold : FontWeight.normal,
      fontStyle: props['italic'] == true ? FontStyle.italic : FontStyle.normal,
    );
  }
}
