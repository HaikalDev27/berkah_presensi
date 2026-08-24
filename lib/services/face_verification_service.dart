import 'dart:io';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'face_embedding_service.dart';

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
/// Ekstraksi face embedding dilakukan DI HP (on-device, lewat
/// FaceEmbeddingService) — service ini hanya bertugas kirim hasil
/// embedding-nya (192 angka) ke backend untuk didaftarkan (enroll) atau
/// dicocokkan (verify) dengan embedding referensi yang tersimpan di server.
///
/// Foto mentah TIDAK PERNAH dikirim ke server lewat service ini — hanya
/// representasi angkanya, lebih ringan & lebih privat.
class FaceVerificationService {
  final ApiClient _apiClient;
  final FaceEmbeddingService _embeddingService = FaceEmbeddingService.instance;

  FaceVerificationService(this._apiClient);

  /// Daftarkan [foto] sebagai wajah referensi untuk user yang sedang login.
  /// Dipanggil dari halaman Profil ("Daftarkan Wajah").
  ///
  /// Melempar [FaceEmbeddingException] kalau wajah tidak terdeteksi di foto,
  /// atau [ApiException] kalau request ke server gagal.
  Future<void> enroll(File foto) async {
    final embedding = await _embeddingService.extractEmbedding(foto);

    await _apiClient.post(
      ApiConfig.enrollFace,
      body: {'embedding': embedding},
      useAuth: true,
    );
  }

  /// Kirim embedding hasil ekstraksi [foto] ke server untuk dicocokkan
  /// dengan embedding referensi karyawan yang sedang login.
  ///
  /// Melempar [FaceEmbeddingException] kalau wajah tidak terdeteksi di foto,
  /// atau [ApiException] kalau request ke server gagal (termasuk kalau
  /// wajah referensi belum pernah didaftarkan — lihat pesan error dari
  /// backend, controllers/WajahController.php).
  Future<FaceVerificationResult> verify(File foto) async {
    final embedding = await _embeddingService.extractEmbedding(foto);

    final response = await _apiClient.post(
      ApiConfig.verifyFace,
      body: {'embedding': embedding},
      useAuth: true,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Response verifikasi wajah tidak valid');
    }

    return FaceVerificationResult.fromJson(data);
  }
}
