import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

enum PacketType {
  json, // Standard UI updates, events, config
  binary, // Images, Tensors, File streams
  dart, // Raw Dart code for dynamic execution (DartP)
}

/// A unified packet wrapper for all incoming data
class IPYPacket {
  final PacketType type;
  final Map<String, dynamic>? jsonData;
  final Uint8List? binaryData;
  final String? dartCode;

  IPYPacket.json(this.jsonData)
      : type = PacketType.json,
        binaryData = null,
        dartCode = null;

  IPYPacket.binary(this.binaryData)
      : type = PacketType.binary,
        jsonData = null,
        dartCode = null;

  IPYPacket.dart(this.dartCode)
      : type = PacketType.dart,
        jsonData = null,
        binaryData = null;
}

class TransportService {
  WebSocketChannel? _channel;
  final StreamController<IPYPacket> _controller = StreamController.broadcast();
  bool _isConnected = false;

  Stream<IPYPacket> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  /// Connects to the Python IPYUI server
  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) => _handleIncoming(message),
        onError: (e) {
          print("Transport Error: $e");
          _isConnected = false;
        },
        onDone: () {
          print("Transport Closed");
          _isConnected = false;
        },
      );
    } catch (e) {
      print("Connection Failed: $e");
      _isConnected = false;
    }
  }

  /// Dispatches incoming raw WebSocket messages into Typed Packets
  void _handleIncoming(dynamic message) {
    if (message is String) {
      // Text Frame: Could be JSON or specialized DartP Protocol
      try {
        final decoded = jsonDecode(message);

        // Protocol Check: Is this wrapped Dart code?
        if (decoded is Map && decoded.containsKey('__dartp_code__')) {
          _controller.add(IPYPacket.dart(decoded['__dartp_code__']));
        } else {
          _controller.add(IPYPacket.json(decoded));
        }
      } catch (e) {
        // If not JSON, treat as raw Dart code if it looks like it
        if (message.trim().startsWith('import') || message.contains(';')) {
          _controller.add(IPYPacket.dart(message));
        } else {
          print("Transport Parsing Error: $e");
        }
      }
    } else if (message is List<int>) {
      // Binary Frame
      _controller.add(IPYPacket.binary(Uint8List.fromList(message)));
    }
  }

  /// Sends JSON event back to Python
  void sendEvent(String id, String type, dynamic value) {
    if (_channel != null) {
      final payload = jsonEncode(
          {"type": "event", "id": id, "handler": type, "value": value});
      _channel!.sink.add(payload);
    }
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
