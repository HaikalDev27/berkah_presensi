/// Model sederhana untuk satu baris riwayat absensi.
/// Nanti field-field ini tinggal disambungkan ke response API backend.
class Absensi {
  final String tanggal; // contoh: "18 Februari 2026"
  final String status; // Hadir / Izin / Sakit / Cuti / Tanpa Keterangan
  final String idAbsensi;
  final String nik;
  final String idUnit;
  final String idJabatan;
  final String checkIn;
  final String checkOut;
  final String jamKerja;

  const Absensi({
    required this.tanggal,
    required this.status,
    required this.idAbsensi,
    required this.nik,
    required this.idUnit,
    required this.idJabatan,
    required this.checkIn,
    required this.checkOut,
    required this.jamKerja,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      tanggal: json['tanggal'],
      status: json['status'],
      idAbsensi: json['id_absensi'],
      nik: json['nik'],
      idUnit: json['id_unit'],
      idJabatan: json['id_jabatan'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      jamKerja: json['jam_kerja'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal,
      'status': status,
      'id_absensi': idAbsensi,
      'nik': nik,
      'id_unit': idUnit,
      'id_jabatan': idJabatan,
      'check_in': checkIn,
      'check_out': checkOut,
      'jam_kerja': jamKerja,
    };
  }

}


