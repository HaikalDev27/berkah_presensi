class loginResponse {
  final String token;
  final String message;

  loginResponse({required this.token, required this.message});

  factory loginResponse.fromJson(Map<String, dynamic> json) {
    return loginResponse(
      token: json['token'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
