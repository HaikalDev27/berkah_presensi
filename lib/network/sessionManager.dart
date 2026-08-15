import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class AuthStorage {
  final _storage = const FlutterSecureStorage();

  // Simpan Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: api_config.tokenKey, value: token);
  }

  // Ambil Token (Untuk cek auto-login)
  Future<String?> getToken() async {
    return await _storage.read(key: api_config.tokenKey);
  }

  // Hapus Token (Untuk Logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: api_config.tokenKey);
  }
}
