import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/absensi.dart';
import '../widgets/logo_badge.dart';
import '../config/api_config.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Absensi item;

  const HistoryDetailScreen({super.key, required this.item});

  /// Hitung durasi kerja dari string jam 'HH:mm' atau 'HH:mm:ss'.
  /// Mengembalikan '-' kalau salah satu jam kosong atau gagal di-parse.
  String get _jamKerja {
    final masuk = item.masuk;
    final keluar = item.keluar;
    if (masuk == null || keluar == null) return '-';
    try {
      final m = _parseTimeOfDay(masuk);
      final k = _parseTimeOfDay(keluar);
      var diff = (k.hour * 60 + k.minute) - (m.hour * 60 + m.minute);
      if (diff < 0) diff += 24 * 60;
      final jam = diff ~/ 60;
      final menit = diff % 60;
      return '${jam}j ${menit}m';
    } catch (_) {
      return '-';
    }
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    final hasFoto = item.fotoBukti != null && item.fotoBukti!.isNotEmpty;
    final hasLokasi = item.latitude != null && item.longitude != null;
    final hasKeterangan = item.keterangan != null && item.keterangan!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header hijau
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Riwayat',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headerTitle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LogoBadge(size: 40),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.textDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.tanggal,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Rincian Absensi', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'ID Absensi', value: item.idAbsensi.toString()),
                    _DetailRow(label: 'Status', value: item.statusLabel),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Keterangan Waktu', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Check In',
                      value: item.masuk ?? '-',
                      icon: Icons.login,
                    ),
                    _DetailRow(
                      label: 'Check Out',
                      value: item.keluar ?? '-',
                      icon: Icons.logout,
                    ),
                    _DetailRow(label: 'Jam Kerja', value: _jamKerja),
                    if (hasKeterangan) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('Catatan', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Text(
                        item.keterangan!,
                        style: AppTextStyles.value,
                      ),
                    ],
                    if (hasLokasi) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('Lokasi', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Latitude',
                        value: item.latitude!,
                        icon: Icons.location_on,
                      ),
                      _DetailRow(label: 'Longitude', value: item.longitude!),
                    ],
                    if (hasFoto) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('Foto Bukti', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          // TODO: sesuaikan ApiConfig.baseUrl kalau nama
                          // konstanta base URL storage kamu berbeda.
                          '${ApiConfig.baseUrl}/uploads/absensi/${item.fotoBukti}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Gagal memuat foto',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _DetailRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.textDark),
                const SizedBox(width: 6),
              ],
              Text(value, style: AppTextStyles.value),
            ],
          ),
        ],
      ),
    );
  }
}