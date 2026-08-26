import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/absensi.dart';
import '../widgets/logo_badge.dart';
import 'history_detail_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _authService = AuthService(_apiClient, _sessionManager);

  late Future<UserModel> _userFuture;
  late Future<List<Absensi>> _absensiFuture;

  // Default: 7 hari terakhir sampai hari ini (bukan tanggal statis lagi).
  late DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  late DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.getProfile();
    _reloadAbsensi();
  }
 
  /// Ambil ulang riwayat absensi sesuai rentang _fromDate/_toDate saat ini.
  /// Return Future supaya bisa di-await oleh RefreshIndicator.
  Future<void> _reloadAbsensi() {
    final future = _authService.getAbsensiHistory(
      dari: _fromDate,
      sampai: _toDate,
    );
    setState(() {
      _absensiFuture = future;
    });
    // Tunggu future-nya selesai (baik sukses maupun error) sebelum
    // RefreshIndicator menyembunyikan animasi loading-nya.
    return future.then((_) {}).catchError((_) {});
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      // Langsung fetch ulang begitu salah satu tanggal berubah.
      _reloadAbsensi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header hijau
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<UserModel>(
                    future: _userFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 60);
                      }
                      return _ProfileHeader(user: snapshot.data!);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('History', style: AppTextStyles.headerTitle),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'From :',
                            date: dateFormat.format(_fromDate),
                            onTap: () => _pickDate(isFrom: true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('—'),
                        ),
                        Expanded(
                          child: _DateField(
                            label: 'To :',
                            date: dateFormat.format(_toDate),
                            onTap: () => _pickDate(isFrom: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Last history attendance',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // List riwayat
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reloadAbsensi,
                child: FutureBuilder<List<Absensi>>(
                  future: _absensiFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Gagal memuat riwayat: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                        ],
                      );
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada riwayat absensi pada rentang tanggal ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    );
                  }

                  return _AbsensiList(absensiList: data);
                },
              ),
            ),
            )
          ],
        ),
      ),
    );
  }
}

class _AbsensiList extends StatelessWidget {
  final List<Absensi> absensiList;

  const _AbsensiList({required this.absensiList});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: absensiList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = absensiList[index];
        return _HistoryCard(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryDetailScreen(item: item),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${user.nmUnit}   ›  ${user.nik}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const LogoBadge(size: 40),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hitung durasi kerja dari string jam 'HH:mm' atau 'HH:mm:ss'.
/// Mengembalikan '-' kalau gagal di-parse.
String _calculateWorkDuration(String masuk, String keluar) {
  try {
    final m = masuk.split(':');
    final k = keluar.split(':');
    final mMinutes = int.parse(m[0]) * 60 + int.parse(m[1]);
    final kMinutes = int.parse(k[0]) * 60 + int.parse(k[1]);
    var diff = kMinutes - mMinutes;
    if (diff < 0) diff += 24 * 60;
    final jam = diff ~/ 60;
    final menit = diff % 60;
    return '${jam}j ${menit}m';
  } catch (_) {
    return '-';
  }
}

class _HistoryCard extends StatelessWidget {
  final Absensi item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHadir = item.absensi == 'H';
    final hasKeterangan = item.keterangan != null && item.keterangan!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.tanggal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 10),
            if (isHadir)
              Row(
                children: [
                  _TimeChip(
                    icon: Icons.login,
                    time: item.masuk ?? '-',
                    label: 'Check in',
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 12),
                  _TimeChip(
                    icon: Icons.logout,
                    time: item.keluar ?? '-',
                    label: 'Check Out',
                  ),
                  const SizedBox(width: 12),
                  _TimeChip(
                    icon: Icons.access_time,
                    time: (item.masuk != null && item.keluar != null)
                        ? _calculateWorkDuration(item.masuk!, item.keluar!)
                        : '-',
                    label: 'Jam Kerja',
                  ),
                ],
              )
            else if (hasKeterangan)
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.keterangan!,
                      style: const TextStyle(color: AppColors.textGrey),
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

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  final String label;

  const _TimeChip({
    required this.icon,
    required this.time,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textDark),
            const SizedBox(width: 4),
            Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        Text(label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
      ],
    );
  }
}