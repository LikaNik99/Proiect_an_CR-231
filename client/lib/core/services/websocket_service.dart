import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

/// Notification types received via WebSocket
enum NotificationType {
  connected,
  notification,
  grade,
  homework,
  attendance,
  announcement,
  pong,
}

/// WebSocket message model
class WsMessage {
  final NotificationType type;
  final Map<String, dynamic> data;

  WsMessage({required this.type, required this.data});

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'notification';
    NotificationType type;

    switch (typeStr) {
      case 'connected':
        type = NotificationType.connected;
        break;
      case 'grade':
        type = NotificationType.grade;
        break;
      case 'homework':
        type = NotificationType.homework;
        break;
      case 'attendance':
        type = NotificationType.attendance;
        break;
      case 'announcement':
        type = NotificationType.announcement;
        break;
      case 'pong':
        type = NotificationType.pong;
        break;
      default:
        type = NotificationType.notification;
    }

    return WsMessage(type: type, data: json);
  }
}

/// Service for WebSocket real-time notifications
class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);


  final _messageController = StreamController<WsMessage>.broadcast();
  Stream<WsMessage> get messageStream => _messageController.stream;


  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await SecureStorageService.getToken();
    if (token == null) {
      debugPrint('WebSocket: No token available');
      return;
    }

    try {

      final baseUrl = AppConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = '$baseUrl/ws?token=$token';

      debugPrint('WebSocket: Connecting to $baseUrl/ws');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _startPingTimer();

      debugPrint('WebSocket: Connected successfully');
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopPingTimer();
    _reconnectTimer?.cancel();

    await _subscription?.cancel();
    await _channel?.sink.close();

    _isConnected = false;
    _connectionController.add(false);
    debugPrint('WebSocket: Disconnected');
  }

  /// Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WsMessage.fromJson(data);
      _messageController.add(wsMessage);

      if (wsMessage.type != NotificationType.pong) {
        debugPrint('WebSocket: Received ${wsMessage.type.name}');
      }
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  /// Handle connection errors
  void _onError(dynamic error) {
    debugPrint('WebSocket: Error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Handle connection closed
  void _onDone() {
    debugPrint('WebSocket: Connection closed');
    _isConnected = false;
    _connectionController.add(false);
    _stopPingTimer();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('WebSocket: Reconnecting (attempt $_reconnectAttempts)');
      connect();
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }

  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Send ping message
  void _sendPing() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        debugPrint('WebSocket: Failed to send ping: $e');
      }
    }
  }

  /// Send a message to the server
  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        debugPrint('WebSocket: Failed to send message: $e');
      }
    }
  }

  /// Clean up resources
  void dispose() {
    _shouldReconnect = false;
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
