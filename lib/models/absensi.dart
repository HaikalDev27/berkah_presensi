class Absensi {
  final int idAbsensi;
  final String tanggal;
  final String? masuk;
  final String? keluar;
  final String absensi; 
  final String? keterangan;
  final String? fotoBukti;
  final String? longitude;
  final String? latitude;
  final String statusApproval;
  final String? catatanApproval;
  final bool diluarRadius;

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
    required this.statusApproval,
    required this.catatanApproval,
    required this.diluarRadius,
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
      statusApproval: (json['status_approval'] as String?) ?? 'pending',
      catatanApproval: json['catatan_approval'] as String?,
      diluarRadius: (json['diluar_radius'] as bool?) ?? false,
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
      'status_approval': statusApproval,
      'catatan_approval': catatanApproval,
      'diluar_radius': diluarRadius,
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

  String get approvalLabel {
    switch (statusApproval) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu Persetujuan';
    }
  }
}
