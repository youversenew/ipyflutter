import 'dart:async';
import '../core/transport.dart';
import 'ui_plugins.dart';
import 'native_plugins.dart';
import 'service_plugins.dart';

typedef PluginHandler = Future<dynamic> Function(
    Map<String, dynamic> data, TransportService transport);

class PluginRegistry {
  static final Map<String, PluginHandler> _plugins = {};

  /// Initialize all 15+ plugins
  static void init() {
    // 1. UI Plugins
    register('toast', UIPlugins.showToast);
    register('dialog', UIPlugins.showDialogBox);
    register('snackbar', UIPlugins.showSnackBar);
    register('launcher', UIPlugins.launchURL);
    register('theme', UIPlugins.setTheme); // Dynamic Fonts/Theme

    // 2. Native Device Plugins
    register('image_picker', NativePlugins.pickImage);
    register('storage_get', NativePlugins.storageGet);
    register('storage_set', NativePlugins.storageSet);
    register('location', NativePlugins.getLocation);
    register('vibrate', NativePlugins.vibrate);
    register('share', NativePlugins.share);

    // 3. External Services (Google/Firebase)
    register('google_pay', ServicePlugins.pay);
    register('firebase_auth', ServicePlugins.firebaseAuth);
    register('analytics', ServicePlugins.logEvent);
    register('ads', ServicePlugins.showAd);
  }

  static void register(String name, PluginHandler handler) {
    _plugins[name] = handler;
  }

  /// Handles incoming JSON commands from Python
  static Future<void> handle(String name, Map<String, dynamic> data,
      TransportService transport) async {
    final handler = _plugins[name];
    if (handler != null) {
      try {
        final result = await handler(data, transport);
        // Send success response back to Python
        if (data.containsKey('request_id')) {
          transport.sendEvent(data['request_id'], "plugin_success", result);
        }
      } catch (e) {
        print("Plugin Error ($name): $e");
        if (data.containsKey('request_id')) {
          transport.sendEvent(data['request_id'], "plugin_error", e.toString());
        }
      }
    } else {
      print("Plugin '$name' not found.");
    }
  }
}
