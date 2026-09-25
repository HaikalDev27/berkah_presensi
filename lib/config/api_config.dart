import 'package:flutter_dotenv/flutter_dotenv.dart';

/// config/api_config.dart
///
/// Menyimpan base URL backend dan daftar path endpoint di satu tempat.
/// Kalau nanti pindah dari WAMP lokal ke InfinityFree, cukup ubah
/// `baseUrl` di sini — tidak perlu mengubah kode di screen manapun.
class ApiConfig {

  // static const String baseUrl = 'http://192.168.137.194/API_Absensi/api';
  // static const String baseUrl = 'http://192.168.100.4/api_presensi/api';
  // static const String baseUrl = 'http://192.168.0.100/api_presensi/api';
  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get apiKey => dotenv.env['API_KEY']!;

  // -------------------------------------------------------------------
  // AUTH ENDPOINTS
  // -------------------------------------------------------------------
  static String get login => '/auth/login';
  static String get me => '/auth/me';
  static String get changePassword => '/auth/change-password';
  static String get signUp => '/auth/signup';
  static String get checkNik => '/auth/check-nik';
  static String get forgotPasswordVerify => '/auth/forgot-password/verify';
  static String get forgotPasswordReset => '/auth/forgot-password/reset';

  // -------------------------------------------------------------------
  // ABSENSI ENDPOINTS
  // -------------------------------------------------------------------
  static String get checkin => '/absensi/checkin';
  static String get checkout => '/absensi/checkout';
  static String get today => '/absensi/today';
  static String get riwayat => '/absensi/riwayat';
  static String get detail => '/absensi/detail';
  static String get batasWaktu => '/absensi/batas-waktu';

  static String get lokasi => '/absensi/lokasi';

  // -------------------------------------------------------------------
  // FACE RECOGNITION ENDPOINTS
  // -------------------------------------------------------------------
  // Kontrak (sudah dibangun di backend, controllers/WajahController.php):
  //   Request  POST (Bearer token) body: { "embedding": [192 angka float] }
  //   Response sukses (enroll):
  //     { "success": true, "message": "...", "data": null }
  //   Response sukses (verify, cocok):
  //     { "success": true, "message": "...", "data": { "match": true,  "score": 0.92 } }
  //   Response sukses (verify, TIDAK cocok — bukan error HTTP, tetap
  //   success:true, supaya UI baca field "match" secara normal):
  //     { "success": true, "message": "...", "data": { "match": false, "score": 0.41 } }
  static String get verifyFace => '/absensi/verify-face';
  static String get enrollFace => '/wajah/enroll';

  static String get updateVersion => '/app-version';

  static String get deviceToken => '/notifikasi/device-token';

  static String get lokasiRumah => '/absensi/lokasi-rumah';
}
