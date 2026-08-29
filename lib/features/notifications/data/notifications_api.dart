import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/features/notifications/data/notification_models.dart';

/// In-app notification feed.
class NotificationsApi {
  final ApiClient _client;
  const NotificationsApi(this._client);

  Future<List<NotificationModel>> notifications() async {
    final res = await _client.dio.get('/notifications');
    return (res.data as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _client.dio.patch('/notifications/$id/read');
  }
}
