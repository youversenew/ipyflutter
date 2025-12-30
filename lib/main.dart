import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
//s
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart'; // For Custom Title Bar
import 'package:provider/provider.dart';

// --- Internal Modules ---
import 'core/transport.dart';
import 'core/node.dart';
import 'core/dartp.dart';
import 'widgets/registry.dart';
import 'plugins/registry.dart';
import 'plugins/ui_plugins.dart';

// --- Global Constants ---
const double kTitleBarHeight = 32.0;
const String kDefaultWsUrl = 'ws://127.0.0.1:8000/ws';

void main() async {
  // 1. Engine Setup
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Core Systems
  WidgetRegistry.init();
  PluginRegistry.init();

  // 3. Desktop Window Setup (Custom Title Bar & Size)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Hides Native Bar
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 4. Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Send error report to Python if connected
    // TransportService().sendEvent("system", "error", details.toString());
  };

  runApp(const IPYRuntimeApp());
}

/// The Root Widget
class IPYRuntimeApp extends StatefulWidget {
  const IPYRuntimeApp({super.key});

  @override
  State<IPYRuntimeApp> createState() => _IPYRuntimeAppState();
}

class _IPYRuntimeAppState extends State<IPYRuntimeApp> {
  // Theme State
  ThemeMode _themeMode = ThemeMode.system;
  String _fontFamily = 'Roboto'; // Default

  void updateTheme(String mode, String? font) {
    setState(() {
      if (mode == 'dark')
        _themeMode = ThemeMode.dark;
      else if (mode == 'light')
        _themeMode = ThemeMode.light;
      else
        _themeMode = ThemeMode.system;

      if (font != null) _fontFamily = font;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPYUI Runtime',
      debugShowCheckedModeBanner: false,

      // Plugin Keys
      navigatorKey: UIPlugins.navKey,
      scaffoldMessengerKey: UIPlugins.snackKey,

      // Theming
      themeMode: _themeMode,
      theme: ThemeData(
        fontFamily: _fontFamily,
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        fontFamily: _fontFamily,
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
      ),

      // Entry Point
      home: const IPYShell(),
    );
  }
}

/// The Main Shell: Handles Window Frame, WebSocket, and DevTools
class IPYShell extends StatefulWidget {
  const IPYShell({super.key});

  @override
  State<IPYShell> createState() => _IPYShellState();
}

class _IPYShellState extends State<IPYShell> with WindowListener {
  // Services
  final TransportService _transport = TransportService();
  final ScrollController _logScrollCtrl = ScrollController();

  // State
  UINode? _rootNode;
  bool _isConnected = false;
  bool _showDevTools = false; // Toggled via F12
  String _windowTitle = "IPYUI App";

  // Logs for DevTools
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _connectToPython();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _transport.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  void _log(String msg) {
    // Add to internal log buffer for F12 console
    setState(() {
      _logs.add(
          "[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $msg");
      if (_logs.length > 500) _logs.removeAt(0); // Cap logs
    });
    // Auto scroll to bottom if DevTools open
    if (_showDevTools && _logScrollCtrl.hasClients) {
      _logScrollCtrl.jumpTo(_logScrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _connectToPython() async {
    _log("Attempting connection to $kDefaultWsUrl...");
    try {
      await _transport.connect(kDefaultWsUrl);
      setState(() => _isConnected = true);
      _log("Connected to Python Server.");

      _transport.stream.listen((packet) {
        if (packet.type == PacketType.json) {
          _handleJsonPacket(packet.jsonData!);
        } else if (packet.type == PacketType.binary) {
          _log("Binary Packet Received: ${packet.binaryData!.length} bytes");
          // Handle binary (DartP)
        }
      }, onDone: () {
        setState(() => _isConnected = false);
        _log("Connection Closed. Retrying in 3s...");
        Future.delayed(const Duration(seconds: 3), _connectToPython);
      });
    } catch (e) {
      setState(() => _isConnected = false);
      _log("Connection Failed: $e. Retrying in 3s...");
      Future.delayed(const Duration(seconds: 3), _connectToPython);
    }
  }

  void _handleJsonPacket(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'update') {
      // 1. UI Tree Update
      setState(() => _rootNode = UINode.fromJson(data['tree']));
      _log("UI Updated: ${_rootNode?.children.length ?? 0} root children");
    } else if (type == 'config') {
      // 2. App Config (Title, Theme, Size)
      if (data['title'] != null) {
        setState(() => _windowTitle = data['title']);
        windowManager.setTitle(data['title']);
      }
      // Pass theme up to Root
      if (data['theme'] != null) {
        final appState = context.findAncestorStateOfType<_IPYRuntimeAppState>();
        appState?.updateTheme(data['theme'], data['font']);
      }
    } else if (type == 'plugin') {
      // 3. Plugin Call
      _log("Plugin Call: ${data['plugin_name']}");
      PluginRegistry.handle(data['plugin_name'], data['data'], _transport);
    }
  }

  @override
  Widget build(BuildContext context) {
    // F12 Listener
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f12) {
          setState(() => _showDevTools = !_showDevTools);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Layer 1: Main Content
            Column(
              children: [
                // 1.1 Custom Window Title Bar (Desktop Only)
                if (!kIsWeb &&
                    (Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isMacOS))
                  _buildCustomTitleBar(),

                // 1.2 App Body
                Expanded(
                  child: _isConnected
                      ? (_rootNode != null
                          ? WidgetRegistry.build(_rootNode!, _transport)
                          : _buildLoading())
                      : _buildDisconnectScreen(),
                ),
              ],
            ),

            // Layer 2: DevTools Overlay (F12)
            if (_showDevTools) _buildDevTools(),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildCustomTitleBar() {
    return GestureDetector(
      onPanStart: (details) => windowManager.startDragging(),
      child: Container(
        height: kTitleBarHeight,
        color:
            Theme.of(context).appBarTheme.backgroundColor ?? Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // Favicon
            const FlutterLogo(size: 16),
            const SizedBox(width: 8),
            // Title
            Expanded(
              child: Text(
                _windowTitle,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Window Controls
            _WindowButton(
                icon: Icons.remove, onTap: () => windowManager.minimize()),
            _WindowButton(
                icon: Icons.check_box_outline_blank,
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                }),
            _WindowButton(
                icon: Icons.close,
                color: Colors.red,
                iconColor: Colors.white,
                onTap: () => windowManager.close()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text("Disconnected from Python",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text("Ensuring server is running at $kDefaultWsUrl"),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDevTools() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "🛠️ IPYUI Developer Tools",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontFamily: 'Courier'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showDevTools = false),
                )
              ],
            ),
            const Divider(color: Colors.white24),
            // Metrics
            Row(
              children: [
                _DevMetric("Status", _isConnected ? "Connected" : "Offline",
                    _isConnected ? Colors.green : Colors.red),
                _DevMetric("Nodes",
                    _rootNode?.children.length.toString() ?? "0", Colors.blue),
                _DevMetric("Transport", "WebSocket", Colors.orange),
              ],
            ),
            const Divider(color: Colors.white24),
            const Text("Event Log:", style: TextStyle(color: Colors.white70)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white24),
                ),
                child: ListView.builder(
                  controller: _logScrollCtrl,
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) => Text(
                    _logs[i],
                    style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'Courier',
                        fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Command Line Input (Mock)
            TextField(
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'Courier'),
              decoration: const InputDecoration(
                prefixText: "> ",
                prefixStyle: TextStyle(color: Colors.greenAccent),
                hintText: "Enter JSON command...",
                hintStyle: TextStyle(color: Colors.white24),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (val) {
                // Send manual event to Python
                _transport.sendEvent("devtools", "manual_exec", val);
                _log("Sent: $val");
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helpers ---

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _WindowButton(
      {required this.icon, required this.onTap, this.color, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: kTitleBarHeight,
          color: color ?? Colors.transparent,
          child: Icon(icon, size: 16, color: iconColor ?? Colors.black54),
        ),
      ),
    );
  }
}

class _DevMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DevMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
