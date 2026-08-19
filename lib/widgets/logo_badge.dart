import 'package:flutter/material.dart';

/// Badge logo bulat kecil yang dipakai di pojok kanan-atas header
/// (Home, History, Detail Riwayat, Profile) — menampilkan
/// assets/images/logo.png dengan background transparan (tanpa lingkaran
/// putih di belakangnya), langsung menyatu dengan warna gradient header.
class LogoBadge extends StatelessWidget {
  final double size;

  const LogoBadge({super.key, this.size = 40});

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

