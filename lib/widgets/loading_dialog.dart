import 'package:flutter/material.dart';

/// Popup loading sederhana: overlay transparan + spinner abu-abu di tengah,
/// sesuai desain "loading_pop_up". Dipakai saat menunggu response API
/// (absensi, ganti password, dll).
class LoadingDialog {
  LoadingDialog._();

  /// Tampilkan popup loading. Tidak bisa ditutup dengan tap di luar atau
  /// tombol back — hanya bisa ditutup lewat [hide].
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const PopScope(
        canPop: false,
        child: _LoadingContent(),
      ),
    );
  }

  /// Tutup popup loading. Aman dipanggil walau dialog sudah tertutup.
  static void hide(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(
          strokeWidth: 5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
        ),
      ),
    );
  }
}
