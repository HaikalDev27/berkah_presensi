import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/lokasi_absensi.dart';
import '../theme/app_theme.dart';

/// widgets/lokasi_confirm_dialog.dart
///
/// Muncul saat user terdeteksi DI LUAR radius semua titik lokasi resmi.
/// Menampilkan peta dengan titik user (merah) + titik-titik lokasi resmi
/// beserta lingkaran radiusnya (hijau), lalu minta konfirmasi.
///
/// Return `true`  -> user konfirmasi "Ya, ini lokasi saya" (lanjut absen,
///                    dengan syarat foto bukti tambahan)
/// Return `false` -> user pilih "Bukan, Coba Lagi" (ambil ulang GPS)
class LokasiConfirmDialog extends StatelessWidget {
  final Position posisiSaatIni;
  final List<LokasiAbsensi> daftarLokasi;

  const LokasiConfirmDialog({
    super.key,
    required this.posisiSaatIni,
    required this.daftarLokasi,
  });

  static Future<bool> show(
    BuildContext context, {
    required Position posisiSaatIni,
    required List<LokasiAbsensi> daftarLokasi,
  }) async {
    final hasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LokasiConfirmDialog(
        posisiSaatIni: posisiSaatIni,
        daftarLokasi: daftarLokasi,
      ),
    );
    return hasil ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final posisiUser = ll.LatLng(posisiSaatIni.latitude, posisiSaatIni.longitude);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lokasi di Luar Radius',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Lokasi Anda terdeteksi berada di luar radius lokasi resmi '
              '(titik hijau di peta). Apakah posisi Anda di peta ini sudah benar?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: posisiUser,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.berkah_presensi',
                    ),
                    CircleLayer(
                      circles: daftarLokasi.map((lok) {
                        return CircleMarker(
                          point: ll.LatLng(lok.latitude, lok.longitude),
                          radius: lok.radiusMeter.toDouble(),
                          useRadiusInMeter: true,
                          color: AppColors.gradientEnd.withOpacity(0.15),
                          borderColor: AppColors.gradientEnd,
                          borderStrokeWidth: 1.5,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: posisiUser,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 36),
                        ),
                        ...daftarLokasi.map(
                          (lok) => Marker(
                            point: ll.LatLng(lok.latitude, lok.longitude),
                            width: 32,
                            height: 32,
                            child: const Icon(Icons.location_on, color: Colors.green, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '📍 Merah = posisi Anda    🟢 Hijau = lokasi resmi',
              style: TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Bukan, Coba Lagi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientEnd),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Ya, Ini Lokasi Saya',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
