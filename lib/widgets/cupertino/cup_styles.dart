import 'package:flutter/cupertino.dart';

class CupStyleParser {
  static Color parseColor(String? hex) {
    if (hex == null) return CupertinoColors.black;
    switch (hex) {
      case "white":
        return CupertinoColors.white;
      case "black":
        return CupertinoColors.black;
      case "blue":
        return CupertinoColors.activeBlue;
      case "green":
        return CupertinoColors.activeGreen;
      case "red":
        return CupertinoColors.destructiveRed;
      case "grey":
        return CupertinoColors.systemGrey;
      case "transparent":
        return CupertinoColors.transparent;
      default:
        try {
          String clean = hex.replaceAll("#", "");
          if (clean.length == 6) clean = "FF$clean";
          return Color(int.parse(clean, radix: 16));
        } catch (e) {
          return CupertinoColors.black;
        }
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
