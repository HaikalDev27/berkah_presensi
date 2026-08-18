import 'user_model.dart';

/// models/login_response.dart
///
/// Representasi field "data" dari response endpoint POST /auth/login:
/// {
///     "token": "...",
///     "user": { "nik": ..., "username": ..., "id_unit": ..., "id_jabatan": ... }
/// }
class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
