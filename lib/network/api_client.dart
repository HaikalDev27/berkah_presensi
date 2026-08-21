import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../session/session_manager.dart';
import 'api_exception.dart';

/// network/api_client.dart
///
/// Satu-satunya tempat yang benar-benar melakukan HTTP request ke
/// backend PHP. Semua service (AuthService, nanti AbsensiService, dst)
/// memakai class ini, bukan memanggil package:http langsung.
///
/// Tugasnya:
/// 1. Menyusun URL lengkap dari ApiConfig.baseUrl + endpoint
/// 2. Menambahkan header Authorization: Bearer <token> otomatis
///    kalau `useAuth: true` (token diambil dari SessionManager)
/// 3. Meng-encode body ke JSON, dan mendekode response JSON dari backend
/// 4. Mengecek field "success" dari response backend kita
///    (format: {success, message, data}) — kalau false, lempar
///    ApiException dengan pesan yang sudah disiapkan backend
class ApiClient {
  final SessionManager _sessionManager;

  ApiClient(this._sessionManager);

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = false,
  }) {
    return _send('POST', endpoint, body: body, useAuth: useAuth);
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool useAuth = true,
  }) {
    return _send('GET', endpoint, queryParams: queryParams, useAuth: useAuth);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) {
    return _send('PUT', endpoint, body: body, useAuth: useAuth);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool useAuth = false,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = <String, String>{
      'Content-Type': 'application/json', 
    };

    // Sisipkan token JWT otomatis untuk endpoint yang butuh login.
    if (useAuth) {
      final token = await _sessionManager.getToken();
      if (token == null) {
        throw ApiException('Sesi tidak ditemukan, silakan login ulang');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          response = await http.get(uri, headers: headers);
      }
    } catch (e) {
      // Error jaringan: tidak ada internet, server tidak bisa dihubungi, dll.
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      // Response bukan JSON valid (misal server mengembalikan HTML error).
      throw ApiException(
        'Response server tidak valid (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final success = decoded['success'] == true;
    final message = decoded['message'] as String? ?? 'Terjadi kesalahan';

    if (!success) {
      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }
}
