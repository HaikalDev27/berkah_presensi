import 'absensi.dart';

class AbsensiResponse {
  final List<Absensi> data;
  final String message;
  final int status;

  AbsensiResponse({
    required this.data,
    required this.message,
    required this.status,
  });

  factory AbsensiResponse.fromJson(Map<String, dynamic> json) {
    return AbsensiResponse(
      data: (json['data'] as List)
          .map((item) => Absensi.fromJson(item))
          .toList(),
      message: json['message'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'message': message,
      'status': status,
    };
  }
}
