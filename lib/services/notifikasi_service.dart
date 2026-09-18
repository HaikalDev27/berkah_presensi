import '../config/api_config.dart';
import '../network/api_client.dart';

/// services/notifikasi_service.dart
class NotifikasiService {
  final ApiClient _apiClient;

  NotifikasiService(this._apiClient);

  /// POST /api/notifikasi/device-token
  /// Dipanggil setiap habis login sukses, kirim FCM token device
  /// ini supaya backend bisa kirim notifikasi ke user ini.
  Future<void> registerDeviceToken(String fcmToken) async {
    await _apiClient.post(
      ApiConfig.deviceToken,
      body: {'fcm_token': fcmToken},
      useAuth: true,
    );
  }
}
