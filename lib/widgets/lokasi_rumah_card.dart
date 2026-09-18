import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/lokasi_absensi.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../services/absensi_service.dart';
import '../session/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/location_helper.dart';

class LokasiRumahCard extends StatefulWidget {
  const LokasiRumahCard({super.key});

  @override
  State<LokasiRumahCard> createState() => _LokasiRumahCardState();
}

class _LokasiRumahCardState extends State<LokasiRumahCard> {
  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _absensiService = AbsensiService(_apiClient);

  late Future<LokasiAbsensi?> _lokasiRumahFuture;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _lokasiRumahFuture = _absensiService.getLokasiRumah();
  }

  void _reload() {
    setState(() {
      _lokasiRumahFuture = _absensiService.getLokasiRumah();
    });
  }

  Future<void> _tandaiLokasiSekarang() async {
    // Konfirmasi dulu, supaya tidak salah tandai kalau HP dipegang
    // sambil bukan di rumah.
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tandai Lokasi Rumah'),
        content: const Text(
          'Pastikan Anda sedang berada DI RUMAH sekarang. '
          'Lokasi GPS saat ini akan disimpan sebagai titik rumah Anda '
          'untuk keperluan absensi (misal WFH).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Saya di Rumah'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _sedangMenyimpan = true);

    try {
      final Position posisi = await LocationHelper.getCurrentPosition();

      await _absensiService.aturLokasiRumah(
        latitude: posisi.latitude.toString(),
        longitude: posisi.longitude.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi rumah berhasil disimpan')),
      );
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home, color: AppColors.gradientEnd),
              SizedBox(width: 8),
              Text('Lokasi Rumah (untuk WFH)', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<LokasiAbsensi?>(
            future: _lokasiRumahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }

              final lokasi = snapshot.data;

              return Text(
                lokasi != null
                    ? 'Sudah diatur (radius ${lokasi.radiusMeter} meter)'
                    : 'Belum diatur',
                style: TextStyle(
                  color: lokasi != null ? Colors.green.shade700 : AppColors.textGrey,
                  fontSize: 13,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sedangMenyimpan ? null : _tandaiLokasiSekarang,
              icon: _sedangMenyimpan
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_sedangMenyimpan ? 'Menyimpan...' : 'Tandai Lokasi Ini sebagai Rumah Saya'),
            ),
          ),
        ],
      ),
    );
  }
}