import 'dart:convert';
import 'dart:io';

import 'package:berkah_presensi/models/absensi.dart';

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

  Future<Absensi?> getToday() async {
    final response = await _apiClient.get(ApiConfig.today, useAuth: true);
    final data = response['data'];
    if (data == null) {
      return null;
    }
    return Absensi.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, int>> getWeeklySummary() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final response = await _apiClient.get(
      ApiConfig.riwayat,
      queryParams: {
        'dari': fmt(startOfWeek),
        'sampai': fmt(now),
      },
      useAuth: true,
    );
    final list = (response['data'] as List).cast<Map<String, dynamic>>();
    final counts = <String, int>{'I': 0, 'S': 0, 'TK': 0, 'C': 0};
    for (final item in list) {
      final status = item['absensi'] as String?;
      if (status != null && counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  Future<String?> getBatasWaktu() async {
    final response = await _apiClient.get(ApiConfig.batasWaktu, useAuth: true);
    return response['data']['jam_batas'] as String?;
  }

}
