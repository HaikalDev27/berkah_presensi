import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sign_up_screen.dart';
import 'main_navigation.dart';
import 'package:berkah_presensi/network/apiClient.dart';
import 'package:berkah_presensi/network/sessionManager.dart';
import 'package:berkah_presensi/widgets/status_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  final _apiClient = ApiClient();
  final _authStorage = AuthStorage();

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = await _apiClient.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      final String token = data['token'] ?? ''; 

      await _authStorage.saveToken(token);

      if (!mounted) return;

      StatusDialog.show(
        context,
        title: 'Berhasil',
        message: 'Selamat datang kembali!',
        isSuccess: true,
        onConfirm: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      StatusDialog.show(
        context,
        isSuccess: false,
        title: 'Gagal',
        message: e.toString(),
        onConfirm: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() => _isLoading = false);
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
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/berkahglobal.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sign In',
                      style: AppTextStyles.headerTitle,
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Form(
                  key: _formKey,
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
                          // TODO: alur lupa password
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

/// Placeholder logo lingkaran "BERKAH" — ganti dengan Image.asset jika file
/// logo resmi sudah tersedia di assets/images/logo.png
class _BerkahLogo extends StatelessWidget {
  final double size;
  const _BerkahLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.public, color: Colors.white, size: 40),
          SizedBox(height: 4),
          Text(
            'BERKAH',
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'GLOBAL BUSINESS',
            style: TextStyle(color: Colors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
