import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';

/// A real-time payment event pushed from the backend gateway.
class PaymentEvent {
  final String type; // 'payment.success' | 'payment.failed'
  final String transactionId;
  final String? sessionId;
  final int amount;
  final String currency;
  final String status;

  PaymentEvent({
    required this.type,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    this.sessionId,
  });

  factory PaymentEvent.fromSocket(String type, Map<String, dynamic> j) => PaymentEvent(
        type: type,
        transactionId: (j['transactionId'] ?? '') as String,
        sessionId: j['sessionId'] as String?,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        currency: (j['currency'] ?? 'GHS') as String,
        status: (j['status'] ?? '') as String,
      );
}

/// Maintains a single authenticated Socket.IO connection and broadcasts payment events.
/// This replaces polling for merchant payment confirmation.
class RealtimeService {
  io.Socket? _socket;
  final _controller = StreamController<PaymentEvent>.broadcast();

  Stream<PaymentEvent> get events => _controller.stream;
  bool get connected => _socket?.connected ?? false;

  /// Connect (or reconnect) with the current auth token.
  void connect(String token) {
    disconnect();
    final socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    socket.onConnect((_) => debugPrint('Realtime connected'));
    socket.onConnectError((e) => debugPrint('Realtime connect error: $e'));
    socket.on('payment.success', (d) => _emit('payment.success', d));
    socket.on('payment.failed', (d) => _emit('payment.failed', d));
    socket.on('payment.refunded', (d) => _emit('payment.refunded', d));
    socket.connect();
    _socket = socket;
  }

  void _emit(String type, dynamic data) {
    if (data is Map) {
      _controller.add(PaymentEvent.fromSocket(type, Map<String, dynamic>.from(data)));
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
