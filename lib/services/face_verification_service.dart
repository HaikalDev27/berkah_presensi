import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// Hasil verifikasi wajah dari server.
class FaceVerificationResult {
  final bool match;
  final double score;

  const FaceVerificationResult({required this.match, required this.score});

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      match: json['match'] == true,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// services/face_verification_service.dart
///
/// Mengirim foto wajah (base64) ke backend untuk dicocokkan dengan foto
/// referensi karyawan yang tersimpan di server, lalu menerima hasil
/// cocok/tidak beserta skor kemiripannya.
///
/// TODO backend: endpoint `ApiConfig.verifyFace` belum ada — lihat komentar
/// di api_config.dart untuk kontrak request/response yang diasumsikan.
class FaceVerificationService {
  final ApiClient _apiClient;

  FaceVerificationService(this._apiClient);

  /// Kirim [foto] ke server untuk dicocokkan dengan foto referensi
  /// karyawan yang sedang login. Melempar [ApiException] kalau request
  /// gagal (misal tidak ada koneksi, atau server error).
  Future<FaceVerificationResult> verify(File foto) async {
    final bytes = await foto.readAsBytes();
    final base64Foto = base64Encode(bytes);

    final response = await _apiClient.post(
      ApiConfig.verifyFace,
      body: {'foto': base64Foto},
      useAuth: true,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Response verifikasi wajah tidak valid');
    }

    return FaceVerificationResult.fromJson(data);
  }
}
