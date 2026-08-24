import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/absensi_dialog.dart';
import '../widgets/status_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/logo_badge.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';
import '../services/biometric_service.dart';
import '../network/api_exception.dart';
import 'package:geolocator/geolocator.dart';
import '../services/absensi_service.dart';
import '../utils/location_helper.dart';
import '../services/camera_permission_service.dart';
import '../services/face_verification_service.dart';
import '../services/face_embedding_service.dart';
import 'face_capture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _authService = AuthService(_apiClient, _sessionManager);
  late final _absensiService = AbsensiService(_apiClient);
  late final _faceVerificationService = FaceVerificationService(_apiClient);

  late Future<UserModel> _userFuture;

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
    _userFuture = _authService.getProfile();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<bool> _verifyBiometric({required String reason}) async {
    final BiometricStatus biometricStatus = await BiometricService.checkStatus();

    if (!context.mounted) return false;

    switch (biometricStatus) {
      case BiometricStatus.available:
        final ok = await BiometricService.authenticate(reason: reason);
        if (!ok && context.mounted) {
          StatusDialog.show(
            context,
            isSuccess: false,
            title: 'Attendence Failed!!!',
            message: 'Verifikasi fingerprint/Face ID gagal, mohon coba lagi!',
          );
        }
        return ok;

      case BiometricStatus.notEnrolled:
        if (context.mounted) {
          StatusDialog.show(
            context,
            isSuccess: false,
            title: 'Attendence Failed!!!',
            message:
                'Belum ada fingerprint/Face ID terdaftar di HP ini. '
                'Silakan daftarkan dulu lewat Pengaturan > Keamanan.',
          );
        }
        return false;

      case BiometricStatus.notSupported:
        // Device/emulator tidak punya sensor biometrik -> lanjut tanpa verifikasi
        return true;

      case BiometricStatus.error:
        if (context.mounted) {
          StatusDialog.show(
            context,
            isSuccess: false,
            title: 'Attendence Failed!!!',
            message: 'Gagal memeriksa sensor fingerprint/Face ID, coba lagi.',
          );
        }
        return false;
    }
  }

  /// Alur lengkap verifikasi wajah: minta izin kamera → buka kamera →
  /// kirim ke server untuk dicocokkan. Dipakai bareng oleh Check In
  /// maupun Check Out supaya perilakunya selalu sama persis.
  ///
  /// Return true kalau wajah cocok & boleh lanjut absen, false kalau
  /// gagal/dibatalkan di titik mana pun (StatusDialog sudah ditampilkan
  /// otomatis di dalam sini kalau gagal, kecuali user membatalkan).
  Future<bool> _verifyFace() async {
    // a. Minta izin kamera dulu.
    final bool izinKamera = await CameraPermissionService.request();
    if (!context.mounted) return false;

    if (!izinKamera) {
      final permanen = await CameraPermissionService.isPermanentlyDenied();
      if (!context.mounted) return false;
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: permanen
            ? 'Izin kamera ditolak permanen. Aktifkan manual lewat '
                'Pengaturan > Aplikasi > Berkah Presensi > Izin > Kamera.'
            : 'Izin kamera dibutuhkan untuk verifikasi wajah.',
      );
      return false;
    }

    // b. Buka kamera depan, minta user ambil foto wajah.
    final File? fotoWajah = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );

    if (!context.mounted) return false;

    if (fotoWajah == null) {
      // User membatalkan pengambilan foto — jangan lanjut kirim absen,
      // tanpa perlu tampilkan pesan gagal (ini pembatalan, bukan error).
      return false;
    }

    // c. Ekstrak embedding di HP, lalu kirim ke server untuk dicocokkan.
    LoadingDialog.show(context);

    bool cocok;
    try {
      final hasil = await _faceVerificationService.verify(fotoWajah);
      cocok = hasil.match;
    } on FaceEmbeddingException catch (e) {
      if (!context.mounted) return false;
      LoadingDialog.hide(context);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: e.message,
      );
      return false;
    } on ApiException catch (e) {
      if (!context.mounted) return false;
      LoadingDialog.hide(context);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: 'Verifikasi wajah gagal: ${e.message}',
      );
      return false;
    }

    if (!context.mounted) return false;
    LoadingDialog.hide(context);

    if (!cocok) {
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: 'Wajah tidak cocok dengan data karyawan terdaftar. '
            'Mohon coba lagi.',
      );
      return false;
    }

    return true;
  }

  /// CHECK-IN — tampilkan AbsensiDialog dulu (pilih Hadir/Sakit/Izin +
  /// comment + foto kalau perlu), baru verifikasi biometrik & wajah, lalu kirim.
  void _openAbsensiDialog() {
    AbsensiDialog.show(
      context,
      onConfirm: (status, comment, photo) async {
        final terverifikasi = await _verifyBiometric(
          reason: 'Verifikasi identitas untuk Check In',
        );
        if (!context.mounted || !terverifikasi) return;

        final wajahCocok = await _verifyFace();
        if (!context.mounted || !wajahCocok) return;

        // Fingerprint + wajah lolos → tampilkan loading & kirim absen.
        LoadingDialog.show(context);

        String? errorMessage;
        bool berhasil = false;

        try {
          final position = await LocationHelper.getCurrentPosition();

          await _absensiService.checkin(
            latitude: position.latitude.toString(),
            longitude: position.longitude.toString(),
            status: _mapStatusLabelToCode(status),
            keterangan: comment.trim().isNotEmpty ? comment.trim() : null,
            photo: photo,
          );

          berhasil = true;
        } on ApiException catch (e) {
          errorMessage = e.message;
        } catch (e) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }

        if (!context.mounted) return;
        LoadingDialog.hide(context);

        if (berhasil) {
          final jam = DateFormat('HH:mm').format(DateTime.now());
          setState(() => _checkInTime = jam);

          StatusDialog.show(
            context,
            isSuccess: true,
            title: 'Attendence Succesfull!',
            message: 'Terimakasih sudah mengirim absen anda!',
          );
        } else {
          StatusDialog.show(
            context,
            isSuccess: false,
            title: 'Attendence Failed!!!',
            message: errorMessage ?? 'Absensi Gagal, Mohon Coba Lagi!',
          );
        }
      },
    );
  }

  /// CHECK-OUT — verifikasi biometrik & wajah dulu (sama persis seperti
  /// Check In), baru kirim checkout ke server.
  Future<void> _handleCheckOut() async {
    final terverifikasi = await _verifyBiometric(
      reason: 'Verifikasi identitas untuk Check Out',
    );
    if (!context.mounted || !terverifikasi) return;

    final wajahCocok = await _verifyFace();
    if (!context.mounted || !wajahCocok) return;

    LoadingDialog.show(context);

    String? errorMessage;
    bool berhasil = false;

    try {
      final position = await LocationHelper.getCurrentPosition();

      await _absensiService.checkout(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );

      berhasil = true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!context.mounted) return;
    LoadingDialog.hide(context);

    if (berhasil) {
      final jam = DateFormat('HH:mm').format(DateTime.now());
      setState(() => _checkOutTime = jam);

      StatusDialog.show(
        context,
        isSuccess: true,
        title: 'Attendence Succesfull!',
        message: 'Terimakasih sudah mengirim absen anda, hati hati dijalan!',
      );
    } else {
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: errorMessage ?? 'Absensi Gagal, Mohon Coba Lagi!',
      );
    }
  }

  /// Ubah label radio ('Hadir'/'Sakit'/'Izin') jadi kode yang dipahami
  /// backend ('H'/'S'/'I').
  String _mapStatusLabelToCode(String label) {
    switch (label) {
      case 'Sakit':
        return 'S';
      case 'Izin':
        return 'I';
      case 'Hadir':
      default:
        return 'H';
    }
  }

  /// Panggil API absensi sesungguhnya (checkin/checkout), termasuk
  /// mengambil lokasi GPS device dulu. Melempar Exception/ApiException
  /// kalau gagal (ditangkap oleh pemanggil di atas).
  Future<void> _kirimAbsensiKeServer({
    required bool isCheckIn,
    required String status,
    required String comment,
    File? photo,
  }) async {
    // Ambil lokasi GPS device saat ini. Kalau GPS mati/izin ditolak,
    // ini akan throw Exception dengan pesan yang jelas (lihat
    // location_helper.dart) — otomatis tertangkap oleh catch di pemanggil.
    final position = await LocationHelper.getCurrentPosition();

    final latitude = position.latitude.toString();
    final longitude = position.longitude.toString();

    if (isCheckIn) {
      final statusCode = _mapStatusLabelToCode(status);

      await _absensiService.checkin(
        latitude: latitude,
        longitude: longitude,
        status: statusCode,
        keterangan: comment.trim().isNotEmpty ? comment.trim() : null,
        photo: photo,
      );
    } else {
      // Checkout tidak butuh status/comment/photo — backend cuma
      // butuh lat/long, dan akan menolak sendiri kalau status hari ini
      // bukan Hadir (lihat guard baru di AbsensiController::checkout()).
      await _absensiService.checkout(
        latitude: latitude,
        longitude: longitude,
      );
    }
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
                      FutureBuilder<UserModel>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(height: 60);
                            Color.fromARGB(255, 102, 93, 93);
                          }
                          return _ProfileHeader(user: snapshot.data!);
                        },
                      ),
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
                          onTap: () => _openAbsensiDialog(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CheckButton(
                          label: 'Check Out',
                          time: _checkOutTime ?? '08:00',
                          color: AppColors.checkOutOrange,
                          onTap: () => _handleCheckOut(),
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
