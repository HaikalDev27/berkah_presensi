import 'package:flutter/material.dart';

/// Warna & style yang dipakai di seluruh aplikasi, diambil dari desain
/// Figma "Berkah Presensi".
class AppColors {
  AppColors._();

  // Gradient hijau khas header (Sign In, Home, History, Profile)
  static const Color gradientStart = Color(0xFF6FE3B4); // hijau muda / mint
  static const Color gradientEnd = Color(0xFF3E9C76); // hijau tua

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );

  static const Color background = Color(0xFFF4F6F5); // abu-abu terang
  static const Color cardWhite = Colors.white;

  static const Color textDark = Color(0xFF2E2E2E);
  static const Color textGrey = Color(0xFF8B8B8B);

  static const Color checkInBlue = Color(0xFF2E9CE0);
  static const Color checkOutOrange = Color(0xFFE0A22E);

  static const Color success = Color(0xFF2ECC71);
  static const Color successBanner = Color(0xFF5FE3C3);
  static const Color danger = Color(0xFFFF5252);

  static const Color izinGreen = Color(0xFF2ECC71);
  static const Color sakitRed = Color(0xFFE74C3C);
  static const Color tanpaKeteranganPurple = Color(0xFF9B59B6);
  static const Color cutiBlue = Color(0xFF3B82F6);
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Poppins';

  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    color: AppColors.textDark,
  );

  static const TextStyle value = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
}

/// ThemeData global untuk MaterialApp.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gradientEnd),
    fontFamily: AppTextStyles.fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
