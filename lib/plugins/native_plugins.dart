import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // Add to pubspec
import 'package:shared_preferences/shared_preferences.dart'; // Add to pubspec
import 'package:geolocator/geolocator.dart'; // Add to pubspec
import 'package:flutter/services.dart'; // For vibration/clipboard
import '../core/transport.dart';

class NativePlugins {
  /// 5. Image Picker (Camera/Gallery)
  static Future<String?> pickImage(
      Map<String, dynamic> data, TransportService t) async {
    final ImagePicker picker = ImagePicker();
    final source =
        data['source'] == 'camera' ? ImageSource.camera : ImageSource.gallery;

    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      // Return base64 or path depending on platform
      final bytes = await image.readAsBytes();
      return base64Encode(bytes); // Sending small images as Base64 to Python
    }
    return null;
  }

  /// 6. Shared Preferences (Local Storage)
  static Future<dynamic> storageGet(
      Map<String, dynamic> data, TransportService t) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(data['key']);
  }

  static Future<void> storageSet(
      Map<String, dynamic> data, TransportService t) async {
    final prefs = await SharedPreferences.getInstance();
    final key = data['key'];
    final value = data['value'];

    if (value is String) prefs.setString(key, value);
    if (value is bool) prefs.setBool(key, value);
    if (value is int) prefs.setInt(key, value);
  }

  /// 7. Geolocation
  static Future<Map<String, double>> getLocation(
      Map<String, dynamic> data, TransportService t) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw "Location services disabled";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw "Permission denied";
    }

    Position pos = await Geolocator.getCurrentPosition();
    return {"lat": pos.latitude, "lng": pos.longitude};
  }

  /// 8. Vibration (Haptics)
  static Future<void> vibrate(
      Map<String, dynamic> data, TransportService t) async {
    HapticFeedback.mediumImpact();
  }

  /// 9. Share Sheet
  static Future<void> share(
      Map<String, dynamic> data, TransportService t) async {
    // Use 'share_plus' package in real impl
    print("Sharing: ${data['text']}");
  }
}
