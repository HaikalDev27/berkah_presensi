import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/status_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/logo_badge.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              Navigator.of(context).pop(); // tutup dialog konfirmasi

              LoadingDialog.show(context);

              // TODO: ganti dengan pemanggilan API logout sesungguhnya
              // (misal hapus token, panggil endpoint logout, dsb).
              await _logoutDiServer();

              if (!context.mounted) return;
              LoadingDialog.hide(context);

              if (!context.mounted) return;
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

  /// Simulasi proses logout — delay singkat lalu selesai.
  /// Ganti isi fungsi ini dengan pemanggilan API logout sesungguhnya.
  Future<void> _logoutDiServer() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _handleChangePassword(BuildContext context) {
    ChangePasswordDialog.show(
      context,
      onConfirm: (oldPass, newPass) async {
        // Tampilkan loading selagi menunggu response server.
        LoadingDialog.show(context);

        // TODO: ganti dengan pemanggilan API ganti password sesungguhnya.
        final bool success = await _gantiPasswordDiServer(oldPass, newPass);

        if (!context.mounted) return;
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

  /// Simulasi pemanggilan API — sukses selama password baru tidak kosong.
  /// Ganti isi fungsi ini dengan http/dio call ke backend sesungguhnya.
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
        child: SingleChildScrollView(
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
                      const Text(
                        'Yuda Aditya Pratama',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'IT Support   ›  100276AB2',
                        style: TextStyle(color: Colors.white70),
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
                      const _ProfileField(
                        icon: Icons.person_outline,
                        label: 'Nama',
                        value: 'Yuda Aditya Pratama',
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
                      const _ProfileField(
                        icon: Icons.badge_outlined,
                        label: 'ID Karyawan',
                        value: '100276AB2',
                      ),
                      const SizedBox(height: 14),
                      const _ProfileField(
                        icon: Icons.work_outline,
                        label: 'Jabatan',
                        value: 'IT Support',
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
