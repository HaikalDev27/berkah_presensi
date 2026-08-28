import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Popup "Buat Password Baru" — dipakai di akhir alur Lupa Password,
/// setelah wajah berhasil diverifikasi. Beda dari ChangePasswordDialog:
/// tidak ada field "Password Lama" (identitas sudah dibuktikan lewat
/// wajah), tapi ada field "Konfirmasi Password Baru" supaya user tidak
/// salah ketik password yang tidak bisa dilihat (obscured).
class SetNewPasswordDialog extends StatefulWidget {
  final void Function(String newPassword) onConfirm;

  const SetNewPasswordDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required void Function(String newPassword) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetNewPasswordDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<SetNewPasswordDialog> createState() => _SetNewPasswordDialogState();
}

class _SetNewPasswordDialogState extends State<SetNewPasswordDialog> {
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.gradientEnd, width: 2),
      ),
    );
  }

  void _handleConfirm() {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.length < 6) {
      setState(() => _errorText = 'Password baru minimal 6 karakter');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorText = 'Konfirmasi password tidak sama');
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirm(newPass);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Password Baru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Wajah Anda sudah terverifikasi. Silakan buat password baru.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password Baru',
              style: TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Password Baru',
              style: TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: _fieldDecoration(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _handleConfirm,
                  child: const Text(
                    'Simpan Password Baru',
                    style: TextStyle(
                      fontSize: 16,
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
    );
  }
}
