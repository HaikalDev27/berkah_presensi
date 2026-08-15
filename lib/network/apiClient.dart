import 'dart:convert';
import 'package:berkah_presensi/models/loginResponse.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'package:berkah_presensi/widgets/status_dialog.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // Fungsi Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse(api_config.loginEndpoint);

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10)); 

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData; 
      } else {
        final errorMessage = responseData['message'] ?? 'Email atau password salah.';
        throw errorMessage;
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
  }
}