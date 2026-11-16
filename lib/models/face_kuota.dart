/// models/face_kuota.dart
///
/// Status kuota percobaan verifikasi wajah saat Check-in (dari server,
/// GET /absensi/face-kuota, atau field "kuota" di respons verify-face).
///
/// Hitungan gagal disimpan di server per karyawan per hari, jadi tetap
/// berlaku walaupun app ditutup lalu dibuka lagi.
class FaceKuota {
  final int maks;
  final int gagal;
  final int sisa;
  final bool habis;

  /// belum | menunggu | disetujui | ditolak
  final String statusBukti;
  final String? catatanAdmin;

  const FaceKuota({
    required this.maks,
    required this.gagal,
    required this.sisa,
    required this.habis,
    required this.statusBukti,
    required this.catatanAdmin,
  });

  factory FaceKuota.fromJson(Map<String, dynamic> json) {
    return FaceKuota(
      maks: (json['maks'] as num?)?.toInt() ?? 3,
      gagal: (json['gagal'] as num?)?.toInt() ?? 0,
      sisa: (json['sisa'] as num?)?.toInt() ?? 3,
      habis: json['habis'] == true,
      statusBukti: (json['status_bukti'] as String?) ?? 'belum',
      catatanAdmin: json['catatan_admin'] as String?,
    );
  }

  /// Foto bukti sudah dikirim (menunggu admin) atau sudah disetujui.
  bool get buktiSudahAda =>
      statusBukti == 'menunggu' || statusBukti == 'disetujui';
}
