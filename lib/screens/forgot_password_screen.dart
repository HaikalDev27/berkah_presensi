import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/status_dialog.dart';
import '../widgets/set_new_password_dialog.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../session/session_manager.dart';
import '../services/auth_service.dart';
import '../services/face_verification_service.dart';
import '../services/face_embedding_service.dart';
import '../services/camera_permission_service.dart';
import 'face_capture_screen.dart';

/// Alur "Lupa Password" — TANPA email/OTP (aplikasi ini tidak punya data
/// kontak karyawan sama sekali). Sebagai gantinya, identitas user
/// dibuktikan lewat kecocokan wajah dengan wajah referensi yang sudah
/// didaftarkan untuk absensi:
///
///   1. User masukkan NIK.
///   2. Ambil foto wajah (kamera depan, sama seperti alur absen).
///   3. Server cocokkan embedding wajah itu dengan wajah referensi NIK
///      tsb. Kalau cocok, server balas "reset_token" berumur pendek.
///   4. User buat password baru (dikirim bareng reset_token).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _nikCtrl = TextEditingController();

  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _authService = AuthService(_apiClient, _sessionManager);
  late final _faceVerificationService = FaceVerificationService(_apiClient);

  bool _isProcessing = false;

  @override
  void dispose() {
    _nikCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFE4E4E4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _handleVerifikasiWajah() async {
    final nik = _nikCtrl.text.trim();

    if (nik.isEmpty) {
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'NIK Belum Diisi',
        message: 'Masukkan NIK Anda terlebih dahulu.',
      );
      return;
    }

    // a. Minta izin kamera dulu — sama seperti alur verifikasi wajah saat
    //    absen (lihat home_screen.dart _verifyFace()).
    final bool izinKamera = await CameraPermissionService.request();
    if (!mounted) return;

    if (!izinKamera) {
      final permanen = await CameraPermissionService.isPermanentlyDenied();
      if (!mounted) return;
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Verifikasi Gagal',
        message: permanen
            ? 'Izin kamera ditolak permanen. Aktifkan manual lewat '
                'Pengaturan > Aplikasi > Berkah Presensi > Izin > Kamera.'
            : 'Izin kamera dibutuhkan untuk verifikasi wajah.',
      );
      return;
    }

    // b. Buka kamera depan, minta user ambil foto wajah.
    final File? fotoWajah = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );

    if (!mounted) return;
    if (fotoWajah == null) return; // user membatalkan

    setState(() => _isProcessing = true);
    LoadingDialog.show(context);

    String resetToken;
    try {
      resetToken =
          await _faceVerificationService.verifyForForgotPassword(nik, fotoWajah);
    } on FaceEmbeddingException catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isProcessing = false);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Verifikasi Gagal',
        message: e.message,
      );
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isProcessing = false);
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Verifikasi Gagal',
        message: e.message,
      );
      return;
    }

    if (!mounted) return;
    LoadingDialog.hide(context);
    setState(() => _isProcessing = false);

    // c. Wajah cocok -> minta user buat password baru.
    SetNewPasswordDialog.show(
      context,
      onConfirm: (newPassword) => _handleSetPasswordBaru(resetToken, newPassword),
    );
  }

  Future<void> _handleSetPasswordBaru(String resetToken, String newPassword) async {
    LoadingDialog.show(context);

    String? errorMessage;
    bool berhasil = false;

    try {
      await _authService.resetPasswordWithToken(
        resetToken: resetToken,
        newPassword: newPassword,
      );
      berhasil = true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    LoadingDialog.hide(context);

    StatusDialog.show(
      context,
      isSuccess: berhasil,
      title: berhasil ? 'Password Berhasil Direset' : 'Reset Gagal',
      message: berhasil
          ? 'Password baru Anda sudah aktif. Silakan login kembali.'
          : (errorMessage ?? 'Reset password gagal, silakan coba lagi.'),
      onConfirm: berhasil
          ? () => Navigator.of(context).pop() // kembali ke Sign In
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, bottom: 40),
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'PT. Berkah Gobal Business',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headerSubtitle,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.face_retouching_natural,
                        color: Colors.white, size: 72),
                    const SizedBox(height: 16),
                    const Text('Lupa Password', style: AppTextStyles.headerTitle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan NIK Anda, lalu verifikasi wajah untuk '
                      'membuktikan identitas Anda. Wajah yang dipakai '
                      'adalah wajah yang sudah terdaftar untuk absensi.',
                      style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                    const Text('NIK', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nikCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Masukkan NIK Anda'),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _handleVerifikasiWajah,
                          icon: const Icon(Icons.face, color: Colors.white),
                          label: const Text(
                            'Verifikasi Wajah',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
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
