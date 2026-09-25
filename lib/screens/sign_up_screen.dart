import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dialog.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../session/session_manager.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

/// Tahapan form sign up. Urutannya linear — user tidak bisa lompat ke
/// tahap berikutnya tanpa menyelesaikan tahap saat ini.
enum _SignUpStep { nik, username, password }

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nikCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _sessionManager = SessionManager();
  late final _apiClient = ApiClient(_sessionManager);
  late final _authService = AuthService(_apiClient, _sessionManager);

  _SignUpStep _step = _SignUpStep.nik;
  bool _isLoading = false;

  /// Nama karyawan hasil cek NIK di step 1, ditampilkan sebagai konfirmasi
  /// di step-step berikutnya ("Mendaftar sebagai [nama]").
  String? _namaKaryawan;

  String? _nikErrorText;
  String? _passwordErrorText;

  @override
  void dispose() {
    _nikCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint,
      {Widget? suffixIcon, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFE4E4E4),
      suffixIcon: suffixIcon,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ============================================================
  // STEP 1 — NIK
  // ============================================================

  Future<void> _handleCekNik() async {
    final nik = _nikCtrl.text.trim();

    if (nik.isEmpty) {
      setState(() => _nikErrorText = 'NIK wajib diisi');
      return;
    }

    setState(() {
      _nikErrorText = null;
      _isLoading = true;
    });
    LoadingDialog.show(context);

    String? errorMessage;
    String? nama;

    try {
      nama = await _authService.checkNik(nik);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception', '');
    }

    if (!mounted) return;
    LoadingDialog.hide(context);
    setState(() => _isLoading = false);

    if (errorMessage != null) {
      setState(() => _nikErrorText = errorMessage);
      return;
    }

    setState(() {
      _namaKaryawan = (nama != null && nama.isNotEmpty) ? nama : null;
      _step = _SignUpStep.username;
    });
  }

  // ============================================================
  // STEP 2 — Username
  // ============================================================

  void _handleLanjutUsername() {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username wajib diisi')),
      );
      return;
    }
    setState(() => _step = _SignUpStep.password);
  }

  // ============================================================
  // STEP 3 — Password (+ konfirmasi) -> submit akun
  // ============================================================

  Future<void> _handleBuatAkun() async {
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (password.length < 6) {
      setState(() => _passwordErrorText = 'Password minimal 6 karakter');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _passwordErrorText = 'Konfirmasi password tidak cocok');
      return;
    }
    setState(() => _passwordErrorText = null);

    LoadingDialog.show(context);

    String? errorMessage;
    bool berhasil = false;

    try {
      await _authService.signUp(
        nik: _nikCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: password,
      );
      berhasil = true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception', '');
    }

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (berhasil) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Akun Berhasil Dibuat'),
          content: const Text(
            'Akun berhasil dibuat, silahkan sign in dan ke halaman profil '
            'anda untuk set up lanjutan.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // kembali ke SignInScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage ?? 'Pendaftaran gagal, coba lagi')));
    }
  }

  // ============================================================
  // Navigasi mundur antar step
  // ============================================================

  void _handleBack() {
    switch (_step) {
      case _SignUpStep.nik:
        Navigator.of(context).pop();
        break;
      case _SignUpStep.username:
        setState(() => _step = _SignUpStep.nik);
        break;
      case _SignUpStep.password:
        setState(() => _step = _SignUpStep.username);
        break;
    }
  }

  int get _stepIndex => _SignUpStep.values.indexOf(_step);

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
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  children: [
                    const Text(
                      'PT. Berkah Gobal Business',
                      style: AppTextStyles.headerSubtitle,
                    ),
                    const SizedBox(height: 20),
                    _BerkahLogoSmall(size: 130),
                    const SizedBox(height: 20),
                    const Text('Sign Up', style: AppTextStyles.headerTitle),
                    const SizedBox(height: 16),
                    _StepIndicator(currentIndex: _stepIndex, totalSteps: 3),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Kembali'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_namaKaryawan != null && _step != _SignUpStep.nik) ...[
                      Text(
                        'Mendaftar sebagai $_namaKaryawan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: switch (_step) {
                        _SignUpStep.nik => _buildStepNik(),
                        _SignUpStep.username => _buildStepUsername(),
                        _SignUpStep.password => _buildStepPassword(),
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Already have an account?  ',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Sign In >',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
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
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepNik() {
    return Column(
      key: const ValueKey('step_nik'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NIK', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _nikCtrl,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            'Enter your NIK',
            errorText: _nikErrorText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'NIK akan dicocokkan dengan data karyawan perusahaan.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 28),
        _primaryButton(
          _isLoading ? 'Memeriksa...' : 'Cek NIK',
          _isLoading ? null : _handleCekNik,
        ),
      ],
    );
  }

  Widget _buildStepUsername() {
    return Column(
      key: const ValueKey('step_username'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Username', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameCtrl,
          decoration: _inputDecoration('Enter your username'),
        ),
        const SizedBox(height: 28),
        _primaryButton('Lanjut', _handleLanjutUsername),
      ],
    );
  }

  Widget _buildStepPassword() {
    return Column(
      key: const ValueKey('step_password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black45,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Konfirmasi Password', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDecoration(
            'Re-enter your password',
            errorText: _passwordErrorText,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.black45,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _primaryButton('Buat Akun', _handleBuatAkun),
      ],
    );
  }
}

/// Indikator titik-titik kecil di header menunjukkan sudah sampai step mana.
class _StepIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;

  const _StepIndicator({required this.currentIndex, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final active = i <= currentIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _BerkahLogoSmall extends StatelessWidget {
  final double size;
  const _BerkahLogoSmall({required this.size});

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