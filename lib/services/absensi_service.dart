import 'dart:convert';
import 'dart:io';

import 'package:berkah_presensi/models/absensi.dart';

import '../config/api_config.dart';
import '../models/absensi.dart';
import '../models/lokasi_absensi.dart';
import '../network/api_client.dart';

class AbsensiService {
  final ApiClient _apiClient;

  AbsensiService(this._apiClient);

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

  Future<List<LokasiAbsensi>> getDaftarLokasi() async {
    final response = await _apiClient.get(ApiConfig.lokasi, useAuth: true);
    return (response['data'] as List)
        .map((item) => LokasiAbsensi.fromJson(item as Map<String, dynamic>))
        .toList();
  }

    /// GET /api/absensi/lokasi-rumah
  /// Return null kalau belum pernah diatur.
  Future<LokasiAbsensi?> getLokasiRumah() async {
    final response = await _apiClient.get(ApiConfig.lokasiRumah, useAuth: true);
    final data = response['data'];
    if (data == null) return null;

    return LokasiAbsensi(
      id: null,
      namaLokasi: 'Rumah Saya',
      latitude: double.parse(data['latitude'].toString()),
      longitude: double.parse(data['longitude'].toString()),
      radiusMeter: int.parse(data['radius_meter'].toString()),
    );
  }

  /// PUT /api/absensi/lokasi-rumah
  Future<void> aturLokasiRumah({
    required String latitude,
    required String longitude,
  }) async {
    await _apiClient.put(
      ApiConfig.lokasiRumah,
      body: {'latitude': latitude, 'longitude': longitude},
      useAuth: true,
    );
  }
}
