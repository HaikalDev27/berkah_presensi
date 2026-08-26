import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../models/update_info.dart';

/// services/update_service.dart
///
/// Cek apakah ada versi APK lebih baru di backend, lalu download +
/// buka installer Android kalau user memilih update sekarang.
class UpdateService {
  final ApiClient _apiClient;

  UpdateService(this._apiClient);

  /// Return null kalau tidak ada update (versi terpasang sudah paling baru).
  /// useAuth: false karena cek update harus tetap jalan walau user
  /// belum/sudah tidak login.
  Future<UpdateInfo?> checkForUpdate() async {
    final response = await _apiClient.get(
      ApiConfig.updateVersion,
      useAuth: false,
    );

    final info = UpdateInfo.fromJson(response['data'] as Map<String, dynamic>);

    final packageInfo = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

    return info.versionCode > currentCode ? info : null;
  }

  /// Download APK dari [apkUrl] (link GitHub Release atau sumber lain),
  /// lalu buka installer Android. onProgress dipanggil berkala dengan
  /// nilai 0.0 - 1.0.
  Future<void> downloadAndInstall(
    String apkUrl, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('Tidak bisa mengakses storage perangkat');
    }
    final savePath = '${dir.path}/update.apk';

    await Dio().download(
      apkUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    // Memicu dialog installer bawaan Android — user tetap perlu tap
    // "Install" di sana, ini proteksi keamanan Android dan tidak bisa
    // dilewati tanpa perangkat berstatus device owner/MDM.
    await OpenFilex.open(savePath);
  }
}
