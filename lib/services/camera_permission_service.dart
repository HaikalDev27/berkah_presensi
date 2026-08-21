import 'package:permission_handler/permission_handler.dart';

/// Helper kecil untuk minta izin kamera sebelum membuka FaceCaptureScreen.
class CameraPermissionService {
  CameraPermissionService._();

  /// Minta izin kamera. Return true kalau diizinkan.
  /// Kalau user sudah pernah tolak permanen ("Don't ask again"), method ini
  /// tetap return false — arahkan user ke Pengaturan aplikasi secara manual.
  static Future<bool> request() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Cek apakah izin ditolak permanen (perlu buka Pengaturan manual).
  static Future<bool> isPermanentlyDenied() async {
    return Permission.camera.isPermanentlyDenied;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
