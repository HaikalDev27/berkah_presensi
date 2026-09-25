import '../config/api_config.dart';
import '../models/login_response.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../session/session_manager.dart';
import '../models/user_model.dart';
import '../models/absensi.dart';
import 'biometric_login_service.dart';

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

  Future<String> checkNik(String nik) async {
    final response = await _apiClient.post(
      ApiConfig.checkNik,
      body: {'nik': nik},
      useAuth: false,
    );
 
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['nama'] as String?) ?? '';
  }
 

  // ===========================================================
  // BIOMETRIC LOGIN (baru)
  // ===========================================================

  /// Intip username yang ter-bind fingerprint di device ini, tanpa prompt.
  /// Dipakai LoginScreen untuk menampilkan tombol "Login sebagai [username]".
  Future<String?> peekBiometricUsername() {
    return BiometricLoginService.peekUsername();
  }

  Future<bool> isBiometricLoginEnabled() {
    return BiometricLoginService.isEnabled();
  }

  /// Aktifkan biometric login untuk akun yang BARU SAJA login manual.
  /// Panggil ini setelah `login()` di atas sukses, bukan sebagai
  /// pengganti login pertama kali.
  Future<BiometricEnableResult> enableBiometricLogin(
    LoginResponse loginResponse,
  ) {
    return BiometricLoginService.enable(loginResponse);
  }

  /// Nonaktifkan biometric login di device ini.
  Future<void> disableBiometricLogin() {
    return BiometricLoginService.disable();
  }

  /// Login pakai fingerprint/Face ID.
  ///
  /// Alur: buka snapshot token tersimpan via BiometricLoginService.login()
  /// (ini yang menampilkan prompt fingerprint) -> lalu VALIDASI ULANG token
  /// itu ke server lewat GET /me (getProfile). Ini penting supaya:
  ///  - token yang sudah di-revoke/expired di server tidak dianggap valid
  ///    hanya karena tersimpan lokal.
  ///  - data user (nama, jabatan, wajah_terdaftar, dst) selalu fresh, bukan
  ///    snapshot lama saat enable() dulu dipanggil.
  ///
  /// Kalau validasi ke server gagal karena token sudah tidak valid,
  /// binding fingerprint di device ini otomatis dimatikan supaya user
  /// tidak stuck mencoba fingerprint yang tidak akan pernah berhasil lagi,
  /// dan harus login manual.
  Future<LoginResponse> loginWithBiometric() async {
    final result = await BiometricLoginService.login();

    if (!result.success || result.loginResponse == null) {
      throw ApiException(
        result.errorMessage ?? 'Login fingerprint gagal, silakan login manual.',
      );
    }

    final localLoginResponse = result.loginResponse!;

    // Simpan sementara ke SessionManager supaya ApiClient bisa memakai
    // token ini untuk memanggil endpoint /me (butuh useAuth: true).
    await _sessionManager.saveSession(
      localLoginResponse.token,
      localLoginResponse.user,
    );

    try {
      final freshUser = await getProfile();
      return LoginResponse(token: localLoginResponse.token, user: freshUser);
    } on ApiException {
      // Token lokal ternyata sudah tidak valid di server (401/expired/dsb).
      await _sessionManager.clearSession();
      await BiometricLoginService.disable();
      throw ApiException(
        'Sesi fingerprint sudah tidak berlaku, silakan login manual.',
      );
    }
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

  Future<void> signUp({
    required String nik,
    required String username,
    required String password,
  }) async {
    await _apiClient.post(
      ApiConfig.signUp,
      body: {
        'nik': nik,
        'username': username,
        'password': password,
      },
      useAuth: false,
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
  ///
  /// Catatan: TIDAK otomatis mematikan biometric login di device ini,
  /// supaya user yang sama bisa langsung pakai fingerprint lagi saat
  /// login berikutnya. Kalau butuh tombol "Logout & matikan fingerprint",
  /// panggil disableBiometricLogin() secara terpisah dari UI.
  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}