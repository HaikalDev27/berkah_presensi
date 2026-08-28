import '../config/api_config.dart';
import '../models/login_response.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';
import '../models/user_model.dart';
import '../models/absensi.dart';

/// services/auth_service.dart
///
/// Fungsi-fungsi terkait autentikasi yang dipanggil LANGSUNG dari
/// screen (misal LoginScreen). Ini "pintu masuk" untuk fitur auth —
/// screen tidak perlu tahu detail ApiClient/endpoint/JSON sama sekali.
class AuthService {
  final ApiClient _apiClient;
  final SessionManager _sessionManager;

  AuthService(this._apiClient, this._sessionManager);

  /// Login dengan username & password.
  /// Kalau berhasil: otomatis menyimpan token + data user ke SessionManager,
  /// lalu mengembalikan LoginResponse (berisi token & user) untuk dipakai
  /// screen kalau perlu (misal langsung menampilkan nama/NIK).
  ///
  /// Kalau gagal (username/password salah, dsb): melempar ApiException
  /// dengan pesan yang berasal dari backend (contoh: "Username atau
  /// password salah").
  Future<LoginResponse> login(String username, String password) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      body: {
        'username': username,
        'password': password,
      },
      useAuth: false, // endpoint login tidak butuh token
    );

    final loginResponse = LoginResponse.fromJson(
      response['data'] as Map<String, dynamic>,
    );

    await _sessionManager.saveSession(loginResponse.token, loginResponse.user);

    return loginResponse;
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConfig.me, useAuth: true);

    final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);

    final token = await _sessionManager.getToken();
    if (token != null) {
      await _sessionManager.saveSession(token, user);
    }

    return user;
  }

  Future<List<Absensi>> getAbsensiHistory({DateTime? dari, DateTime? sampai}) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final response = await _apiClient.get(
      ApiConfig.riwayat,
      queryParams: (dari != null && sampai != null)
          ? {'dari': fmt(dari), 'sampai': fmt(sampai)}
          : null,
      useAuth: true,
    );

    final absensiList = (response['data'] as List)
        .map((item) => Absensi.fromJson(item))
        .toList();

    return absensiList;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.put(
      ApiConfig.changePassword,
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
      useAuth: true,
    );
  }

  /// Langkah terakhir alur "Lupa Password": set password baru pakai
  /// [resetToken] yang didapat dari FaceVerificationService.verifyForForgotPassword.
  ///
  /// Tidak butuh login (useAuth: false) — user memang belum bisa login,
  /// identitasnya sudah dibuktikan lewat verifikasi wajah di langkah
  /// sebelumnya (reset_token adalah buktinya, umurnya cuma 5 menit).
  Future<void> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.put(
      ApiConfig.forgotPasswordReset,
      body: {
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      useAuth: false,
    );
  }

  /// Logout: cukup hapus sesi lokal.
  /// (Backend memakai JWT stateless — tidak ada endpoint logout di server,
  /// karena tidak ada tabel token/session yang perlu dihapus di database.)
  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}
