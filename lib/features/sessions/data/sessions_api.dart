import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/features/sessions/data/session_models.dart';

/// Creating and resolving the signed tap/QR session two devices share.
class SessionsApi {
  final ApiClient _client;
  const SessionsApi(this._client);

  Future<SessionPayload> createSession({required int amount, String? description, String channel = 'NFC'}) async {
    final res = await _client.dio.post('/sessions', data: {
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
      'channel': channel,
    });
    return SessionPayload.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SessionPayload> resolveSession(String id) async {
    final res = await _client.dio.get('/sessions/$id');
    return SessionPayload.fromJson(res.data as Map<String, dynamic>);
  }
}
