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

/// A real-time money-request event pushed from the backend gateway.
class RequestEvent {
  final String type; // 'request.created' | 'request.paid' | 'request.declined' | 'request.cancelled'
  final String requestId;
  final int amount;
  final String currency;
  final String status;
  final String? note;

  RequestEvent({
    required this.type,
    required this.requestId,
    required this.amount,
    required this.currency,
    required this.status,
    this.note,
  });

  factory RequestEvent.fromSocket(String type, Map<String, dynamic> j) => RequestEvent(
        type: type,
        requestId: (j['requestId'] ?? '') as String,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        currency: (j['currency'] ?? 'GHS') as String,
        status: (j['status'] ?? '') as String,
        note: j['note'] as String?,
      );
}

/// Maintains a single authenticated Socket.IO connection and broadcasts payment events.
/// This replaces polling for merchant payment confirmation.
class RealtimeService {
  io.Socket? _socket;
  final _controller = StreamController<PaymentEvent>.broadcast();
  final _requestController = StreamController<RequestEvent>.broadcast();

  Stream<PaymentEvent> get events => _controller.stream;
  Stream<RequestEvent> get requestEvents => _requestController.stream;
  bool get connected => _socket?.connected ?? false;

  /// Connect (or reconnect). [tokenProvider] is called on every connection
  /// attempt so reconnects always carry a fresh token — Firebase ID tokens
  /// expire hourly, and a stale one made the socket silently die for good.
  void connect(Future<String?> Function() tokenProvider) {
    disconnect();
    final socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.auth = (dynamic cb) {
      tokenProvider().then(
        (token) => cb({'token': token ?? ''}),
        onError: (_) => cb({'token': ''}),
      );
    };
    socket.onConnect((_) => debugPrint('Realtime connected'));
    socket.onConnectError((e) => debugPrint('Realtime connect error: $e'));
    socket.on('payment.success', (d) => _emit('payment.success', d));
    socket.on('payment.failed', (d) => _emit('payment.failed', d));
    socket.on('payment.refunded', (d) => _emit('payment.refunded', d));
    socket.on('request.created', (d) => _emitRequest('request.created', d));
    socket.on('request.paid', (d) => _emitRequest('request.paid', d));
    socket.on('request.declined', (d) => _emitRequest('request.declined', d));
    socket.on('request.cancelled', (d) => _emitRequest('request.cancelled', d));
    socket.connect();
    _socket = socket;
  }

  void _emit(String type, dynamic data) {
    if (data is Map) {
      _controller.add(PaymentEvent.fromSocket(type, Map<String, dynamic>.from(data)));
    }
  }

  void _emitRequest(String type, dynamic data) {
    if (data is Map) {
      _requestController.add(RequestEvent.fromSocket(type, Map<String, dynamic>.from(data)));
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
    _requestController.close();
  }
}
