import 'package:geolocator/geolocator.dart';

/// utils/location_helper.dart
///
/// Helper untuk mengambil koordinat lokasi device saat ini, dipakai
/// untuk absensi check-in & check-out (backend mewajibkan lat/long).
///
/// Melempar Exception dengan pesan yang jelas kalau:
/// - GPS/layanan lokasi mati
/// - Izin lokasi ditolak
/// - Izin lokasi ditolak permanen (harus diaktifkan manual lewat Pengaturan)
class LocationHelper {
  static Future<Position> getCurrentPosition() async {
    // 1. Cek apakah layanan lokasi (GPS) aktif di device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Aktifkan GPS/Lokasi terlebih dahulu untuk melakukan absensi.');
    }

    // 2. Cek izin lokasi, minta izin kalau belum diberikan
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak. Absensi membutuhkan akses lokasi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan > Aplikasi > (nama app) > Izin > Lokasi.',
      );
    }

    // 3. Ambil posisi saat ini
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
