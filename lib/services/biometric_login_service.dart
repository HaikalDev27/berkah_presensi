import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login_response.dart';
import '../models/user_model.dart';
import 'biometric_service.dart';

/// services/biometric_login_service.dart
///
/// Binding akun <-> device: fingerprint/Face ID dipakai sebagai "kunci"
/// untuk membuka snapshot LoginResponse (token + user) yang sudah disimpan
/// aman di device ini. OS TIDAK PERNAH memberi tahu app "fingerprint milik
/// siapa" — jadi jaminan "device ini hanya untuk akun ini" berasal dari
/// kebijakan (1 device = 1 user), bukan dari sistem biometriknya sendiri.
///
/// Hanya 1 akun yang bisa aktif per device di implementasi ini. Kalau akun
/// lain melakukan enable() di device yang sama, binding sebelumnya
/// tergantikan.
class BiometricLoginService {
  BiometricLoginService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'biometric_login_token';
  static const _keyUserJson = 'biometric_login_user_json';

  /// Cek apakah ada akun ter-bind di device ini (tanpa prompt fingerprint).
  static Future<bool> isEnabled() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  /// Intip username yang ter-bind, untuk ditampilkan di layar login
  /// sebagai "Login sebagai [username] dengan fingerprint?" — tanpa perlu
  /// prompt fingerprint dulu. Null kalau belum ada binding.
  static Future<String?> peekUsername() async {
    final userJson = await _storage.read(key: _keyUserJson);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map).username;
    } catch (_) {
      return null;
    }
  }

  /// Aktifkan biometric login untuk [loginResponse] (token + user hasil
  /// login manual yang baru saja sukses).
  static Future<BiometricEnableResult> enable(
    LoginResponse loginResponse, {
    String reason = 'Verifikasi fingerprint untuk mengaktifkan login cepat',
  }) async {
    final status = await BiometricService.checkStatus();

    switch (status) {
      case BiometricStatus.notSupported:
        return BiometricEnableResult.failure(
          'Device ini tidak memiliki sensor fingerprint/Face ID.',
        );
      case BiometricStatus.notEnrolled:
        return BiometricEnableResult.failure(
          'Belum ada fingerprint/Face ID terdaftar di HP ini. '
          'Silakan daftarkan dulu lewat Pengaturan > Keamanan.',
        );
      case BiometricStatus.error:
        return BiometricEnableResult.failure(
          'Gagal memeriksa sensor fingerprint/Face ID.',
        );
      case BiometricStatus.available:
        final ok = await BiometricService.authenticate(reason: reason);
        if (!ok) {
          return BiometricEnableResult.failure(
            'Verifikasi fingerprint/Face ID gagal atau dibatalkan.',
          );
        }
        await _storage.write(key: _keyToken, value: loginResponse.token);
        await _storage.write(
          key: _keyUserJson,
          value: jsonEncode(loginResponse.user.toJson()),
        );
        return BiometricEnableResult.success();
    }
  }

  /// Coba buka binding tersimpan lewat fingerprint/Face ID. Akan
  /// menampilkan prompt sistem.
  ///
  /// PENTING: ini hanya mengembalikan snapshot token+user yang tersimpan
  /// LOKAL — token bisa saja sudah expired/revoked di server. Sebaiknya
  /// dipanggil lewat `AuthService.loginWithBiometric()` yang langsung
  /// memvalidasi ulang ke server (lihat auth_service.dart).
  static Future<BiometricLoginResult> login({
    String reason = 'Verifikasi fingerprint untuk login',
  }) async {
    final enabled = await isEnabled();
    if (!enabled) {
      return BiometricLoginResult.failure(
        'Login fingerprint belum diaktifkan di device ini.',
      );
    }

    final status = await BiometricService.checkStatus();
    if (status != BiometricStatus.available) {
      // Sensor hilang / fingerprint dihapus dari pengaturan HP setelah
      // sebelumnya di-enable -> matikan binding supaya tidak stuck.
      await disable();
      return BiometricLoginResult.failure(
        'Fingerprint/Face ID tidak lagi tersedia di device ini. '
        'Silakan login manual dan aktifkan ulang.',
      );
    }

    final ok = await BiometricService.authenticate(reason: reason);
    if (!ok) {
      return BiometricLoginResult.failure(
        'Verifikasi fingerprint/Face ID gagal atau dibatalkan.',
      );
    }

    final token = await _storage.read(key: _keyToken);
    final userJson = await _storage.read(key: _keyUserJson);

    if (token == null || userJson == null) {
      return BiometricLoginResult.failure(
        'Data login tersimpan tidak ditemukan, silakan login manual.',
      );
    }

    try {
      final user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return BiometricLoginResult.success(
        LoginResponse(token: token, user: user),
      );
    } catch (_) {
      return BiometricLoginResult.failure(
        'Data login tersimpan rusak, silakan login manual.',
      );
    }
  }

  /// Nonaktifkan biometric login di device ini (hapus snapshot tersimpan).
  static Future<void> disable() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserJson);
  }
}

class BiometricEnableResult {
  final bool success;
  final String? errorMessage;

  BiometricEnableResult._(this.success, this.errorMessage);

  factory BiometricEnableResult.success() => BiometricEnableResult._(true, null);
  factory BiometricEnableResult.failure(String message) =>
      BiometricEnableResult._(false, message);
}

class BiometricLoginResult {
  final bool success;
  final LoginResponse? loginResponse;
  final String? errorMessage;

  BiometricLoginResult._(this.success, this.loginResponse, this.errorMessage);

  factory BiometricLoginResult.success(LoginResponse loginResponse) =>
      BiometricLoginResult._(true, loginResponse, null);
  factory BiometricLoginResult.failure(String message) =>
      BiometricLoginResult._(false, null, message);
}