class LokasiAbsensi {
  final int? id; 
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final int radiusMeter;

  LokasiAbsensi({
    required this.id,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
  });

  factory LokasiAbsensi.fromJson(Map<String, dynamic> json) {
    return LokasiAbsensi(
      id: json['id'] as int?,
      namaLokasi: json['nama_lokasi'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radiusMeter: int.parse(json['radius_meter'].toString()),
    );
  }
}
