/// models/user_model.dart
///
/// Representasi data user, field-nya PERSIS mengikuti apa yang
/// dikembalikan backend di endpoint login & me — tidak ada field
/// karangan (misal "nama") karena tabel `login` memang tidak
/// menyimpan itu.
class UserModel {
  final String nik;
  final String username;
  final String idUnit;
  final String idJabatan;

  UserModel({
    required this.nik,
    required this.username,
    required this.idUnit,
    required this.idJabatan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nik: json['nik'] as String,
      username: json['username'] as String,
      idUnit: json['id_unit'] as String,
      idJabatan: json['id_jabatan'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'username': username,
      'id_unit': idUnit,
      'id_jabatan': idJabatan,
    };
  }
}
