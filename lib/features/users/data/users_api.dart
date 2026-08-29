import 'package:tappay/core/network/api_client.dart';

/// The signed-in user's own account and devices.
class UsersApi {
  final ApiClient _client;
  const UsersApi(this._client);

  Future<Map<String, dynamic>> me() async {
    final res = await _client.dio.get('/users/me');
    return res.data as Map<String, dynamic>;
  }

  /// Update the signed-in user's own profile. Only the fields passed are changed.
  Future<Map<String, dynamic>> updateProfile({String? displayName, String? phone}) async {
    final res = await _client.dio.patch('/users/me', data: {
      'displayName': ?displayName,
      'phone': ?phone,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> registerDevice({required String deviceId, String? platform, String? pushToken}) async {
    await _client.dio.post('/users/me/devices', data: {
      'deviceId': deviceId,
      'platform': ?platform,
      'pushToken': ?pushToken,
    });
  }
}
