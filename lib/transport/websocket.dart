import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class IpyTransport {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  // Connect to Python Server (default localhost:8000)
  void connect({String url = 'ws://127.0.0.1:8000/ws'}) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (message) {
          final decoded = jsonDecode(message);
          _controller.add(decoded);
        },
        onError: (error) => print("WS Error: $error"),
        onDone: () => print("WS Closed"),
      );
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void sendEvent(String id, String eventType, dynamic value) {
    if (_channel != null) {
      final payload = jsonEncode(
          {"type": "event", "id": id, "handler": eventType, "value": value});
      _channel!.sink.add(payload);
    }
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
