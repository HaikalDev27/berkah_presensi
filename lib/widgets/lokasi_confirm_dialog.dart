import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
class LokasiConfirmDialog extends StatefulWidget {
  final Position posisiSaatIni;
  final List<LokasiAbsensi> daftarLokasi;

  const LokasiConfirmDialog({
    super.key,
    required this.posisiSaatIni,
    required this.daftarLokasi,
  });

  static Future<File?> show(
    BuildContext context, {
    required Position posisiSaatIni,
    required List<LokasiAbsensi> daftarLokasi,
  }) {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LokasiConfirmDialog(
        posisiSaatIni: posisiSaatIni,
        daftarLokasi: daftarLokasi,
      ),
    );
  }

  @override
  State<LokasiConfirmDialog> createState() => _LokasiConfirmDialogState();
}

class _LokasiConfirmDialogState extends State<LokasiConfirmDialog> {
  bool _tahapFoto = false;
  File? _fotoDipilih;
  bool _sedangAmbilFoto = false;

  Future<void> _ambilFoto() async {
    setState(() => _sedangAmbilFoto = true);
    try {
      final picker = ImagePicker();
      final hasil = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (hasil != null) {
        setState(() => _fotoDipilih = File(hasil.path));
      }
    } finally {
      if (mounted) setState(() => _sedangAmbilFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // paksa user pakai tombol di dalam dialog, bukan back/tap luar
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _tahapFoto ? _buildTahapFoto() : _buildTahapPeta(),
        ),
      ),
    );
  }

  Widget _buildTahapPeta() {
    final posisiUser = ll.LatLng(widget.posisiSaatIni.latitude, widget.posisiSaatIni.longitude);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Lokasi di Luar Radius',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              options: MapOptions(initialCenter: posisiUser, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.berkah.presensi', // sesuaikan applicationId Anda
                ),
                CircleLayer(
                  circles: widget.daftarLokasi.map((lok) {
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
                    ...widget.daftarLokasi.map(
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
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Bukan, Coba Lagi'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientEnd),
                // BUKAN Navigator.pop lagi -- pindah TAHAP di dialog yang sama.
                onPressed: () => setState(() => _tahapFoto = true),
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
    );
  }

  Widget _buildTahapFoto() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt, color: AppColors.gradientEnd),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Lampirkan Foto Bukti',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Anda berada di luar radius lokasi resmi. Mohon lampirkan foto '
          'sebagai bukti kehadiran Anda di lokasi ini.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _sedangAmbilFoto ? null : _ambilFoto,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _sedangAmbilFoto
                ? const Center(child: CircularProgressIndicator())
                : _fotoDipilih == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                            SizedBox(height: 4),
                            Text('Ketuk untuk Ambil Foto', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _fotoDipilih!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _tahapFoto = false),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientEnd),
                // Tombol disabled sampai foto benar-benar diambil.
                onPressed: _fotoDipilih == null
                    ? null
                    : () => Navigator.of(context).pop(_fotoDipilih),
                child: const Text('Kirim Absensi', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}