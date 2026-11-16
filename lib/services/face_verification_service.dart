import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/face_kuota.dart';
import 'face_embedding_service.dart';

/// Hasil verifikasi wajah dari server.
class FaceVerificationResult {
  final bool match;
  final double score;

  /// Status kuota percobaan — hanya terisi kalau verifikasi untuk Check-in.
  final FaceKuota? kuota;

  const FaceVerificationResult({
    required this.match,
    required this.score,
    this.kuota,
  });

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    final kuotaJson = json['kuota'];
    return FaceVerificationResult(
      match: json['match'] == true,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      kuota: kuotaJson is Map<String, dynamic>
          ? FaceKuota.fromJson(kuotaJson)
          : null,
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
  ///
  /// [untukCheckin] = true khusus untuk verifikasi saat Check-in: server
  /// menghitung percobaan gagal (maks 3 per hari) dan membalas status
  /// kuota di `FaceVerificationResult.kuota`. Check-out tidak memakainya.
  Future<FaceVerificationResult> verify(
    File foto, {
    bool untukCheckin = false,
  }) async {
    final embedding = await _embeddingService.extractEmbedding(foto);

    final response = await _apiClient.post(
      ApiConfig.verifyFace,
      body: {
        'embedding': embedding,
        if (untukCheckin) 'tujuan': 'checkin',
      },
      useAuth: true,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Response verifikasi wajah tidak valid');
    }

    return FaceVerificationResult.fromJson(data);
  }

  /// Status kuota percobaan verifikasi wajah Check-in hari ini.
  Future<FaceKuota> getKuota() async {
    final response = await _apiClient.get(ApiConfig.faceKuota, useAuth: true);
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Response status kuota tidak valid');
    }
    return FaceKuota.fromJson(data);
  }

  /// Kirim foto bukti identitas ke admin (hanya bisa setelah kuota habis).
  /// Foto diperkecil dulu kalau terlalu besar (batas server 2 MB).
  Future<void> kirimBukti(File foto) async {
    final bytes = await _siapkanFotoBukti(foto);

    await _apiClient.post(
      ApiConfig.faceBukti,
      body: {'foto_base64': 'data:image/png;base64,${base64Encode(bytes)}'},
      useAuth: true,
    );
  }

  static const int _maksBytesBukti = 1500 * 1024;

  /// Kalau file sudah kecil dikirim apa adanya. Kalau besar, diperkecil
  /// bertahap sebagai PNG (lossless, warna tidak bergeser).
  Future<List<int>> _siapkanFotoBukti(File foto) async {
    final Uint8List asli = await foto.readAsBytes();
    if (asli.length <= _maksBytesBukti) return asli;

    final decoded = img.decodeImage(asli);
    if (decoded == null) {
      throw ApiException('Foto bukti tidak dapat diproses, silakan ulangi.');
    }

    img.Image gambar = decoded;
    List<int> hasil = asli;
    while (hasil.length > _maksBytesBukti && gambar.width > 320) {
      gambar = img.copyResize(gambar, width: (gambar.width * 0.8).round());
      hasil = img.encodePng(gambar);
    }
    return hasil;
  }

  /// Dipakai KHUSUS oleh alur "Lupa Password" — user BELUM login (tidak
  /// ada token JWT), jadi NIK harus dikirim manual di body (bukan
  /// diambil dari token seperti [verify]).
  ///
  /// Kalau wajah [foto] cocok dengan wajah referensi milik [nik],
  /// server membalas sebuah "reset_token" berumur pendek (5 menit) yang
  /// dipakai di langkah berikutnya (set password baru).
  ///
  /// Melempar [FaceEmbeddingException] kalau wajah tidak terdeteksi di
  /// foto, atau [ApiException] kalau NIK tidak ditemukan / wajah belum
  /// terdaftar / wajah tidak cocok.
  Future<String> verifyForForgotPassword(String nik, File foto) async {
    final embedding = await _embeddingService.extractEmbedding(foto);

    final response = await _apiClient.post(
      ApiConfig.forgotPasswordVerify,
      body: {'nik': nik, 'embedding': embedding},
      useAuth: false,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic> || data['reset_token'] is! String) {
      throw ApiException('Response verifikasi wajah tidak valid');
    }

    return data['reset_token'] as String;
  }
}
