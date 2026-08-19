class UserModel {
  final String nik;
  final String username;
  final String nama;
  final String idUnit;
  final String nmUnit;
  final String idJabatan;
  final String nmJabatan;

  UserModel({
    required this.nik,
    required this.username,
    required this.nama,
    required this.idUnit,
    required this.nmUnit,
    required this.idJabatan,
    required this.nmJabatan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nik: json['nik'] as String,
      username: json['username'] as String,
      nama: json['nama'] as String,
      idUnit: json['id_unit'] as String,
      nmUnit: json['nm_unit'] as String,
      idJabatan: json['id_jabatan'] as String,
      nmJabatan: json['nm_jabatan'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'username': username,
      'nama': nama,
      'id_unit': idUnit,
      'nm_unit': nmUnit,
      'id_jabatan': idJabatan,
      'nm_jabatan': nmJabatan,
    };
  }
}