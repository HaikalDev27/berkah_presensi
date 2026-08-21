import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../network/api_client.dart';

/// services/absensi_service.dart
///
/// Fungsi-fungsi terkait absensi yang dipanggil dari screen.
/// Sama seperti AuthService, screen tidak perlu tahu detail endpoint/JSON.
class AbsensiService {
  final ApiClient _apiClient;

  AbsensiService(this._apiClient);

  /// POST /api/absensi/checkin
  ///
  /// `status` WAJIB salah satu dari: 'H' (Hadir), 'I' (Izin), 'S' (Sakit).
  /// `keterangan` opsional secara backend (validasi wajib/tidak ditangani
  /// di sisi Flutter/UI, lihat AbsensiDialog).
  /// `photo` opsional — kalau diisi, otomatis di-encode ke base64 dan
  /// dikirim sebagai field `foto_base64`. Backend akan menyimpannya
  /// sebagai file fisik dan path-nya disimpan ke kolom foto_bukti.
  Future<void> checkin({
    required String latitude,
    required String longitude,
    required String status,
    String? keterangan,
    File? photo,
  }) async {
    String? fotoBase64;

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      // Prefix "data:image/jpeg;base64," dipakai backend untuk deteksi
      // ekstensi file. ImagePicker dari kamera selalu hasilkan JPEG.
      fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    await _apiClient.post(
      ApiConfig.checkin,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
        if (fotoBase64 != null) 'foto_base64': fotoBase64,
      },
      useAuth: true,
    );
  }

  /// PUT /api/absensi/checkout
  /// Backend mewajibkan latitude & longitude BARU (bukan sisa dari checkin).
  /// Backend juga menolak kalau status absensi hari ini bukan 'H' (Hadir).
  Future<void> checkout({
    required String latitude,
    required String longitude,
  }) async {
    await _apiClient.put(
      ApiConfig.checkout,
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
      useAuth: true,
    );
  }
}
