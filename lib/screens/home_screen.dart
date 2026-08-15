import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/absensi_dialog.dart';
import '../widgets/status_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/logo_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  String? _checkInTime;
  String? _checkOutTime;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _openAbsensiDialog({required bool isCheckIn}) {
    AbsensiDialog.show(
      context,
      onConfirm: (status, comment) async {
        // Tampilkan loading selagi menunggu response server.
        LoadingDialog.show(context);

        // TODO: ganti dengan pemanggilan API absensi sesungguhnya.
        final bool berhasil = await _kirimAbsensiKeServer(
          isCheckIn: isCheckIn,
          status: status,
          comment: comment,
        );

        if (!context.mounted) return;
        LoadingDialog.hide(context);

        if (berhasil) {
          final jam = DateFormat('HH:mm').format(DateTime.now());
          setState(() {
            if (isCheckIn) {
              _checkInTime = jam;
            } else {
              _checkOutTime = jam;
            }
          });

          StatusDialog.show(
            context,
            isSuccess: true,
            title: 'Attendence Succesfull!',
            message: isCheckIn
                ? 'Terimakasih sudah mengirim absen anda!'
                : 'Terimakasih sudah mengirim absen anda, hati hati dijalan!',
          );
        } else {
          StatusDialog.show(
            context,
            isSuccess: false,
            title: 'Attendence Failed!!!',
            message: 'Absensi Gagal, Mohon Coba Lagi!',
          );
        }
      },
    );
  }

  /// Simulasi pemanggilan API — selalu sukses setelah delay 1.5 detik.
  /// Ganti isi fungsi ini dengan http/dio call ke backend sesungguhnya.
  Future<bool> _kirimAbsensiKeServer({
    required bool isCheckIn,
    required String status,
    required String comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final jamText = DateFormat('HH:mm').format(_now);
    final tanggalText = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(_now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header hijau
              ClipPath(
                clipper: _BottomWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ProfileHeader(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$jamText WIB',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.checkInBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tanggalText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            const Text(
                              'Jadwal Anda Hari Ini',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '07:00 WIB – 16:00 WIB',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CheckButton(
                          label: 'Check In',
                          time: _checkInTime ?? '08:00',
                          color: AppColors.checkInBlue,
                          onTap: () => _openAbsensiDialog(isCheckIn: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CheckButton(
                          label: 'Check Out',
                          time: _checkOutTime ?? '08:00',
                          color: AppColors.checkOutOrange,
                          onTap: () => _openAbsensiDialog(isCheckIn: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.person,
                            iconColor: AppColors.izinGreen,
                            label: 'Izin',
                            value: '0 Hari',
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.sick,
                            iconColor: AppColors.sakitRed,
                            label: 'Sakit',
                            value: '0 Hari',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.help,
                            iconColor: AppColors.tanpaKeteranganPurple,
                            label: 'Tanpa Keterangan',
                            value: '0 Hari',
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.work,
                            iconColor: AppColors.cutiBlue,
                            label: 'Cuti',
                            value: '0 Hari',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keterangan :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yuda Aditya Pratama',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'IT Support   ›  100276AB2',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const LogoBadge(size: 40),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final VoidCallback onTap;

  const _CheckButton({
    required this.label,
    required this.time,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time WIB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Clipper untuk lekukan lengkung di bagian bawah header (sesuai desain).
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
