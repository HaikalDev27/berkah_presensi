/// Model sederhana untuk satu baris riwayat absensi.
/// Nanti field-field ini tinggal disambungkan ke response API backend.
class Absensi {
  final int idAbsensi;
  final String tanggal;
  final String? masuk;
  final String? keluar;
  final String absensi; // kode: 'H', 'I', 'S', dst
  final String? keterangan;
  final String? fotoBukti; // path relatif, null kalau tidak ada foto
  final String? longitude;
  final String? latitude;

  const Absensi({
    required this.idAbsensi,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.absensi,
    required this.keterangan,
    required this.fotoBukti,
    required this.longitude,
    required this.latitude,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      idAbsensi: json['id_absensi'] as int,
      tanggal: json['tanggal'] as String,
      masuk: json['masuk'] as String?,
      keluar: json['keluar'] as String?,
      absensi: json['absensi'] as String,
      keterangan: json['keterangan'] as String?,
      fotoBukti: json['foto_bukti'] as String?,
      longitude: json['longitude'] as String?,
      latitude: json['latitude'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_absensi': idAbsensi,
      'tanggal': tanggal,
      'masuk': masuk,
      'keluar': keluar,
      'absensi': absensi,
      'keterangan': keterangan,
      'foto_bukti': fotoBukti,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  String get statusLabel {
    switch (absensi) {
      case 'H':
        return 'Hadir';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      case 'C':
        return 'Cuti';
      case 'TK':
        return 'Tanpa Keterangan';
      case 'OFF':
        return 'Libur';
      default:
        return absensi;
    }
  }
}


