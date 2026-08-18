import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// session/session_manager.dart
///
/// Bertugas menyimpan, membaca, dan menghapus data sesi (token JWT +
/// data user) di penyimpanan lokal HP, memakai package shared_preferences.
///
/// Ini yang membuat user tidak perlu login ulang setiap kali membuka
/// aplikasi — saat app dibuka, cek isLoggedIn() untuk menentukan
/// halaman awal (ke home kalau sudah ada sesi, ke login kalau belum).
class SessionManager {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  /// Simpan token + data user setelah login berhasil.
  Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Ambil token tersimpan (dipakai ApiClient untuk header Authorization).
  /// Mengembalikan null kalau belum pernah login / sudah logout.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Ambil data user tersimpan (dipakai untuk tampilan profil, dsb).
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);

    if (userJson == null) {
      return null;
    }

    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  /// Cek apakah user sedang dalam status login.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Hapus sesi (dipanggil saat logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
