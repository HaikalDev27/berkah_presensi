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
}

/// Data dummy dipakai supaya UI bisa langsung dilihat tanpa backend.
final List<Absensi> dummyAbsensiList = [
  const Absensi(
    tanggal: '18 Februari 2026',
    status: 'Hadir',
    idAbsensi: '100276AB2',
    nik: '0008736282',
    idUnit: '27',
    idJabatan: '3',
    checkIn: '06:45',
    checkOut: '16:00',
    jamKerja: '07:00',
  ),
  const Absensi(
    tanggal: '17 Februari 2026',
    status: 'Hadir',
    idAbsensi: '100276AB2',
    nik: '0008736282',
    idUnit: '27',
    idJabatan: '3',
    checkIn: '07:00',
    checkOut: '16:00',
    jamKerja: '07:00',
  ),
  const Absensi(
    tanggal: '16 Februari 2026',
    status: 'Hadir',
    idAbsensi: '100276AB2',
    nik: '0008736282',
    idUnit: '27',
    idJabatan: '3',
    checkIn: '07:00',
    checkOut: '16:00',
    jamKerja: '07:00',
  ),
];
