/// config/api_config.dart
///
/// Menyimpan base URL backend dan daftar path endpoint di satu tempat.
/// Kalau nanti pindah dari WAMP lokal ke InfinityFree, cukup ubah
/// `baseUrl` di sini — tidak perlu mengubah kode di screen manapun.
class ApiConfig {
  // -------------------------------------------------------------------
  // BASE URL
  // -------------------------------------------------------------------
  // PENTING — sesuaikan dengan environment testing Anda:
  //
  // 1. Android Emulator (mengakses WAMP di komputer yang sama)
  //    gunakan 10.0.2.2 (alias khusus emulator untuk "localhost" host):
  //      static const String baseUrl = 'http://10.0.2.2/API_Absensi/api';
  //
  // 2. HP fisik yang terhubung ke WiFi yang sama dengan komputer WAMP,
  //    gunakan IP lokal komputer Anda (cek dengan `ipconfig` di cmd,
  //    cari "IPv4 Address", contoh 192.168.1.10):
  //      static const String baseUrl = 'http://192.168.1.10/API_Absensi/api';
  //
  // 3. Setelah deploy ke InfinityFree, ganti dengan domain aslinya:
  //      static const String baseUrl = 'https://namadomainanda.infinityfreeapp.com/api';

  static const String baseUrl = 'http://192.168.137.194/API_Absensi/api';
  // static const String baseUrl = 'http://192.168.100.4/api_presensi/api';

  // -------------------------------------------------------------------
  // AUTH ENDPOINTS
  // -------------------------------------------------------------------
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // -------------------------------------------------------------------
  // ABSENSI ENDPOINTS
  // -------------------------------------------------------------------
  static const String checkin = '/absensi/checkin';
  static const String checkout = '/absensi/checkout';
  static const String today = '/absensi/today';
  static const String riwayat = '/absensi/riwayat';
  static const String detail = '/absensi/detail';
}
