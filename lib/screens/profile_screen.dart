import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/status_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/logo_badge.dart';
import 'sign_in_screen.dart';
import '../services/auth_service.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../session/session_manager.dart';
import '../models/user_model.dart';
import '../services/face_verification_service.dart';
import '../services/face_embedding_service.dart';
import '../services/camera_permission_service.dart';
import 'face_capture_screen.dart';

// 1. DIUBAH MENJADI STATEFULWIDGET
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Tempat menampung data user hasil fetch API
  UserModel? currentUser;
  
  late final SessionManager _sessionManager;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final FaceVerificationService _faceVerificationService;
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    // Inisialisasi service di initState agar API hanya dipanggil 1x
    _sessionManager = SessionManager();
    _apiClient = ApiClient(_sessionManager);
    _authService = AuthService(_apiClient, _sessionManager);
    _faceVerificationService = FaceVerificationService(_apiClient);
    _userFuture = _authService.getProfile(); // Ganti sesuai nama fungsi di tempatmu
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Apakah anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              LoadingDialog.show(context);
              await _logoutDiServer();

              if (!mounted) return;
              LoadingDialog.hide(context);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutDiServer() async {
    await _authService.logout();
  }

  /// Daftarkan / perbarui wajah referensi user — buka kamera, ambil foto,
  /// ekstrak embedding di HP, lalu kirim ke server untuk disimpan.
  Future<void> _handleDaftarkanWajah(BuildContext context) async {
    final bool izinKamera = await CameraPermissionService.request();
    if (!context.mounted) return;

    if (!izinKamera) {
      final permanen = await CameraPermissionService.isPermanentlyDenied();
      if (!context.mounted) return;
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Attendence Failed!!!',
        message: permanen
            ? 'Izin kamera ditolak permanen. Aktifkan manual lewat '
                'Pengaturan > Aplikasi > Berkah Presensi > Izin > Kamera.'
            : 'Izin kamera dibutuhkan untuk mendaftarkan wajah.',
      );
      return;
    }

    final File? fotoWajah = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );

    if (!context.mounted) return;
    if (fotoWajah == null) return; // user membatalkan

    LoadingDialog.show(context);

    try {
      await _faceVerificationService.enroll(fotoWajah);

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      StatusDialog.show(
        context,
        isSuccess: true,
        title: 'Update successful!!',
        message: 'Wajah Anda berhasil didaftarkan sebagai referensi absensi.',
      );
    } on FaceEmbeddingException catch (e) {
      if (!context.mounted) return;
      LoadingDialog.hide(context);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'update failed!!!',
        message: e.message,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      LoadingDialog.hide(context);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'update failed!!!',
        message: 'Gagal mendaftarkan wajah: ${e.message}',
      );
    }
  }

  void _handleChangePassword(BuildContext context) {
    ChangePasswordDialog.show(
      context,
      onConfirm: (oldPass, newPass) async {
        LoadingDialog.show(context);
        final bool success = await _gantiPasswordDiServer(oldPass, newPass);

        if (!mounted) return;
        LoadingDialog.hide(context);

        StatusDialog.show(
          context,
          isSuccess: success,
          title: success ? 'Update successful!!' : 'update failed!!!',
          message: success
              ? 'Password anda telah berhasil diganti!'
              : 'Password anda gagal diganti!!',
        );
      },
    );
  }

  Future<bool> _gantiPasswordDiServer(String oldPass, String newPass) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return newPass.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            // Berikan indikator loading di tengah layar saat pertama kali buka
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading profile'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No profile data'));
            }

            // Data berhasil didapat
            final user = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipPath(
                    clipper: _BottomWaveClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.topRight,
                            child: LogoBadge(size: 40),
                          ),
                          const Text(
                            'PT. Berkah Gobal Business',
                            style: AppTextStyles.headerSubtitle,
                          ),
                          const SizedBox(height: 16),
                          const CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 50),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Halo, ${user.nama}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          
                          // 3. JABATAN & NIK DI HEADER
                          Text(
                            '${user.nmJabatan}  ›  ${user.nik}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // 4. FIELD DETAIL SEKARANG MENGGUNAKAN DATA ASLI API
                          _ProfileField(
                            icon: Icons.person_outline,
                            label: 'Nama',
                            value: user.nama,
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            icon: Icons.lock_outline,
                            label: 'Password',
                            value: '***********',
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.textGrey),
                              onPressed: () => _handleChangePassword(context),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            icon: Icons.badge_outlined,
                            label: 'ID Karyawan / NIK',
                            value: user.nik,
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            icon: Icons.work_outline,
                            label: 'Jabatan',
                            value: user.nmJabatan,
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            icon: Icons.business_outlined,
                            label: 'Unit',
                            value: user.nmUnit,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleDaftarkanWajah(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.gradientEnd),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.face_retouching_natural, color: AppColors.gradientEnd),
                              label: const Text(
                                'DAFTARKAN WAJAH',
                                style: TextStyle(
                                  color: AppColors.gradientEnd,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleLogout(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.logout, color: AppColors.danger),
                              label: const Text(
                                'LOG OUT',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                Text(value, style: AppTextStyles.value),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

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
