import 'package:flutter/material.dart';

class StyleParser {
  static Color parseColor(String? hex) {
    if (hex == null) return Colors.transparent;
    if (hex == "white") return Colors.white;
    if (hex == "black") return Colors.black;
    if (hex == "blue") return Colors.blue;
    if (hex == "gray") return Colors.grey;
    if (hex == "transparent") return Colors.transparent;

    // Handle #RRGGBB
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static EdgeInsets parsePadding(dynamic padding) {
    if (padding is int || padding is double) {
      return EdgeInsets.all(padding.toDouble());
    }
    // Expand for List [l, t, r, b] logic if needed
    return EdgeInsets.zero;
  }

  static MainAxisAlignment parseMainAxis(String? align) {
    switch (align) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
    }
  }
}
