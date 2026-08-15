import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/absensi.dart';
import '../widgets/logo_badge.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Absensi item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          item.tanggal,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Rincian Absensi', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Absensi', value: item.status),
                    _DetailRow(label: 'ID Absensi', value: item.idAbsensi),
                    _DetailRow(label: 'NIK', value: item.nik),
                    _DetailRow(label: 'ID Unit', value: item.idUnit),
                    _DetailRow(label: 'ID Jabatan', value: item.idJabatan),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Keterangan Waktu', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Check In',
                      value: item.checkIn,
                      icon: Icons.login,
                    ),
                    _DetailRow(
                      label: 'Check Out',
                      value: item.checkOut,
                      icon: Icons.logout,
                    ),
                    _DetailRow(label: 'Jam Kerja', value: item.jamKerja),
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
