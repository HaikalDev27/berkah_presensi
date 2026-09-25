import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dialog.dart';
import 'sign_up_screen.dart';
import 'main_navigation.dart';
import 'forgot_password_screen.dart';
import 'package:berkah_presensi/models/login_response.dart';
import 'package:berkah_presensi/network/api_client.dart';
import 'package:berkah_presensi/session/session_manager.dart';
import 'package:berkah_presensi/services/auth_service.dart';
import 'package:berkah_presensi/widgets/status_dialog.dart';
import 'package:berkah_presensi/network/api_exception.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:berkah_presensi/services/notifikasi_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _authService = AuthService(_apiClient, _sessionManager);

  late final _updateService = UpdateService(_apiClient);

  bool _isLoading = false;

  // --- Biometric login (baru) ---
  String? _biometricUsername; // null = belum ada binding fingerprint di device ini

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _checkBiometricLogin();
  }

  Future<void> _checkForUpdate() async {
    try {
      final update = await _updateService.checkForUpdate();
      if (update != null && mounted) {
        showUpdateDialog(context, update, _updateService);
      }
    } catch (_) {
      // Gagal cek update (misal tidak ada koneksi) — abaikan diam-diam.
    }
  }

  /// Cek apakah device ini sudah punya binding fingerprint ke suatu akun.
  /// Tidak menampilkan prompt fingerprint — cuma baca metadata lokal.
  Future<void> _checkBiometricLogin() async {
    final username = await _authService.peekBiometricUsername();
    if (!mounted) return;
    setState(() => _biometricUsername = username);
  }

  Future<void> _handleBiometricLogin() async {
    LoadingDialog.show(context);

    LoginResponse? loginResponse;
    String? errorMessage;

    try {
      loginResponse = await _authService.loginWithBiometric();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (loginResponse == null) {
      // Refresh status tombol (mungkin binding baru saja dimatikan otomatis
      // karena token sudah tidak valid di server).
      await _checkBiometricLogin();
      if (!mounted) return;
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Login Gagal',
        message: errorMessage ?? 'Terjadi kesalahan, coba lagi.',
      );
      return;
    }

    await _afterLoginSuccess(loginResponse, offerEnableBiometric: false);
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFE4E4E4),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _reloadData() async {
    _usernameCtrl.text = '';
    _passwordCtrl.text = '';
  }

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    LoadingDialog.show(context);

    try {
      final loginResponse = await _authService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;
      await _afterLoginSuccess(loginResponse, offerEnableBiometric: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Gagal',
        message: e.message,
        onConfirm: () {
          Navigator.of(context).pop();
        },
      );
      print('Gagal login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dipanggil setelah login berhasil, baik lewat password maupun
  /// fingerprint. Menangani: tawaran aktivasi biometric login (kalau
  /// relevan), registrasi FCM token, dan navigasi ke home.
  Future<void> _afterLoginSuccess(
    LoginResponse loginResponse, {
    required bool offerEnableBiometric,
  }) async {
    if (offerEnableBiometric) {
      await _maybeOfferEnableBiometric(loginResponse);
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );

    try {
      await FirebaseMessaging.instance.requestPermission();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final notifikasiService = NotifikasiService(_apiClient);
        await notifikasiService.registerDeviceToken(fcmToken);
      }
    } catch (e) {
      print('Gagal registrasi device token: $e');
    }
  }

  /// Tawarkan aktivasi biometric login setelah login manual berhasil.
  /// Dilewati kalau device tidak punya sensor / belum ada fingerprint
  /// terdaftar di HP (supaya tidak menawarkan sesuatu yang pasti gagal).
  Future<void> _maybeOfferEnableBiometric(LoginResponse loginResponse) async {
    final alreadyEnabled = await _authService.isBiometricLoginEnabled();
    final currentBiometricUsername = await _authService.peekBiometricUsername();

    final isDifferentAccount = alreadyEnabled &&
        currentBiometricUsername != null &&
        currentBiometricUsername != loginResponse.user.username;

    if (!mounted) return;

    // Kalau device ini sudah bind ke akun yang SAMA, tidak perlu tanya lagi.
    if (alreadyEnabled && !isDifferentAccount) return;

    final mauAktifkan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aktifkan Login Fingerprint?'),
        content: Text(
          isDifferentAccount
              ? 'Device ini sebelumnya terhubung dengan akun lain. '
                'Lanjutkan akan menggantinya dengan akun ini.'
              : 'Lain kali Anda bisa login lebih cepat pakai fingerprint/Face ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti Saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (mauAktifkan != true) return;

    final result = await _authService.enableBiometricLogin(loginResponse);

    if (!mounted) return;

    if (!result.success) {
      // Gagal aktifkan (misal user batalkan prompt) bukan error fatal —
      // login tetap lanjut seperti biasa, cukup kasih tahu lewat SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Gagal mengaktifkan fingerprint.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header hijau dengan logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, bottom: 40),
                  decoration:
                      const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: Column(
                    children: [
                      const Text(
                        'PT. Berkah Gobal Business',
                        style: AppTextStyles.headerSubtitle,
                      ),
                      const SizedBox(height: 20),
                      _BerkahLogo(size: 150),
                      const SizedBox(height: 20),
                      const Text('Sign In', style: AppTextStyles.headerTitle),
                    ],
                  ),
                ),
                // Form
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Form(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_biometricUsername != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.fingerprint),
                            label: Text('Login sebagai $_biometricUsername'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _handleBiometricLogin,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('atau login manual'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      const Text('Username', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: _inputDecoration('Enter your username'),
                      ),
                      const SizedBox(height: 20),
                      const Text('Password', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black45,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: AppColors.gradientEnd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _handleSignIn,
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Not registered yet?  ',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up >',
                                style: TextStyle(
                                  color: AppColors.gradientEnd,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo resmi "Berkah Global Business" dari assets/images/logo.png.
class _BerkahLogo extends StatelessWidget {
  final double size;
  const _BerkahLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}