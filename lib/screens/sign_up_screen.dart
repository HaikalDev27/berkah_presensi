import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _nikCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nikCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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

  void _handleSignUp() async {
    LoadingDialog.show(context);

    // TODO: ganti dengan pemanggilan API sign-up sesungguhnya.
    final bool berhasil = await _signUpKeServer(
      _usernameCtrl.text,
      _nikCtrl.text,
      _passwordCtrl.text,
    );

    if (!context.mounted) return;
    LoadingDialog.hide(context);

    if (berhasil) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran gagal, coba lagi')),
      );
    }
  }

  /// Simulasi pemanggilan API — selalu sukses setelah delay 1.5 detik.
  /// Ganti isi fungsi ini dengan http/dio call ke backend sesungguhnya.
  Future<bool> _signUpKeServer(
    String username,
    String nik,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
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
                    const Text(
                      'PT. Berkah Gobal Business',
                      style: AppTextStyles.headerSubtitle,
                    ),
                    const SizedBox(height: 20),
                    _BerkahLogoSmall(size: 130),
                    const SizedBox(height: 20),
                    const Text('Sign Up', style: AppTextStyles.headerTitle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Username', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameCtrl,
                      decoration: _inputDecoration('Enter your username'),
                    ),
                    const SizedBox(height: 20),
                    const Text('NIK', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nikCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Enter your NIK'),
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
                    const SizedBox(height: 28),
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
                          onPressed: _handleSignUp,
                          child: const Text(
                            'Sign Up',
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
