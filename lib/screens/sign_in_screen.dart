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

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
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

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    LoadingDialog.show(context);

    try {
      await _authService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );

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
    } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header hijau dengan logo
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
                  )
                ),
              ),
            ],
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
