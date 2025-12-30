import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add to pubspec
import 'package:google_fonts/google_fonts.dart'; // Add to pubspec
import '../core/transport.dart';
import '../main.dart'; // Access to global navigator key

class UIPlugins {
  // Access global context via a GlobalKey (assumed set in main.dart)
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> snackKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 1. Toast / Snackbar
  static Future<void> showSnackBar(
      Map<String, dynamic> data, TransportService t) async {
    final msg = data['message'] ?? "";
    final color = data['color'] == 'red' ? Colors.red : Colors.black87;

    snackKey.currentState?.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: Duration(seconds: 2),
    ));
  }

  static Future<void> showToast(
      Map<String, dynamic> data, TransportService t) async {
    // Simple console fallback if no native toast package
    print("TOAST: ${data['message']}");
  }

  /// 2. Native Dialogs
  static Future<dynamic> showDialogBox(
      Map<String, dynamic> data, TransportService t) async {
    if (navKey.currentContext == null) return;

    return showDialog(
      context: navKey.currentContext!,
      builder: (ctx) => AlertDialog(
        title: Text(data['title'] ?? "Alert"),
        content: Text(data['content'] ?? ""),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 3. URL Launcher
  static Future<void> launchURL(
      Map<String, dynamic> data, TransportService t) async {
    final Uri url = Uri.parse(data['url']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// 4. Dynamic Theme & Google Fonts
  static Future<void> setTheme(
      Map<String, dynamic> data, TransportService t) async {
    // Example: Update global font based on Python request
    // "font": "Roboto", "Lato", "Open Sans"
    final fontName = data['font'];
    if (fontName != null) {
      // In a real app, use Provider to notify the MaterialApp builder
      print("Changing App Font to $fontName");
    }
  }
}
