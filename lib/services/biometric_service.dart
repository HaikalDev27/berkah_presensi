import 'package:local_auth/local_auth.dart';

/// Status ketersediaan biometrik di device — dipakai supaya UI bisa kasih
/// pesan yang tepat ke user, bukan cuma "gagal" generik.
enum BiometricStatus {
  /// Siap dipakai — device punya sensor DAN sudah ada fingerprint/Face ID
  /// yang terdaftar di pengaturan sistem.
  available,

  /// Device punya sensor tapi user belum daftarkan fingerprint/Face ID
  /// apa pun di pengaturan HP-nya.
  notEnrolled,

  /// Device/emulator sama sekali tidak punya sensor biometrik.
  notSupported,

  /// Terjadi error lain saat mengecek (jarang terjadi).
  error,
}

/// Service kecil untuk autentikasi fingerprint / Face ID.
/// Dipanggil sebelum mengirim absensi (check in / check out) ke server.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// Cek status biometrik device secara detail (lihat [BiometricStatus]).
  static Future<BiometricStatus> checkStatus() async {
    try {
      final bool supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricStatus.notSupported;

      final bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return BiometricStatus.notEnrolled;

      final List<BiometricType> available =
          await _auth.getAvailableBiometrics();
      if (available.isEmpty) return BiometricStatus.notEnrolled;

      return BiometricStatus.available;
    } catch (_) {
      return BiometricStatus.error;
    }
  }

  /// Versi ringkas — dipakai kalau cuma butuh true/false cepat.
  static Future<bool> isAvailable() async {
    return await checkStatus() == BiometricStatus.available;
  }

  /// Tampilkan prompt fingerprint/Face ID bawaan sistem.
  /// Return true kalau berhasil diverifikasi, false kalau gagal/dibatalkan.
  static Future<bool> authenticate({
    String reason = 'Verifikasi identitas untuk melakukan absensi',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true, // hanya fingerprint/Face ID, tanpa PIN/pola
          stickyAuth: true, // tetap jalan walau app sempat pindah ke background
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

