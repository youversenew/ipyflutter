import 'dart:async';
import 'package:flutter/widgets.dart';
import 'node.dart';
import 'transport.dart';
import 'dartp.dart';

/// The central controller for the IPYUI Runtime.
class IPYEngine extends ChangeNotifier {
  final TransportService _transport = TransportService();
  final DartPManager _dartP = DartPManager();

  UINode? _rootNode;
  UINode? get rootNode => _rootNode;

  bool _ready = false;
  bool get isReady => _ready;

  BuildContext? _context; // Reference for DartP navigation actions

  IPYEngine() {
    _init();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _init() async {
    // 1. Connect Transport
    // Adjust URL for Emulator (10.0.2.2) or Device (IP)
    await _transport.connect('ws://127.0.0.1:8000/ws');

    // 2. Listen to the 3-Type Protocol Stream
    _transport.stream.listen((packet) {
      switch (packet.type) {
        case PacketType.json:
          _handleJson(packet.jsonData!);
          break;
        case PacketType.binary:
          _dartP.processBinary(packet.binaryData!);
          break;
        case PacketType.dart:
          _dartP.executeDart(packet.dartCode!, _context);
          break;
      }
    });
  }

  /// Handles UI Tree Updates and Config from JSON
  void _handleJson(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'update') {
      // Full Tree Rebuild
      _rootNode = UINode.fromJson(data['tree']);
      _ready = true;
      notifyListeners();
    } else if (type == 'patch') {
      // TODO: Implement partial tree patching logic here
      // find node by ID -> replace props -> notifyListeners()
    } else if (type == 'event_ack') {
      // Acknowledge event processing
    }
  }

  /// Sends user interaction events back to Python
  void dispatchEvent(String nodeId, String eventType, dynamic value) {
    _transport.sendEvent(nodeId, eventType, value);
  }

  @override
  void dispose() {
    _transport.dispose();
    super.dispose();
  }
}
