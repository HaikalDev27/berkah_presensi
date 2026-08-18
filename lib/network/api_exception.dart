/// network/api_exception.dart
///
/// Exception khusus yang dilempar saat request ke API gagal —
/// baik karena backend mengembalikan `success: false`, maupun
/// karena masalah koneksi (tidak ada internet, server mati, dll).
///
/// Screen/widget cukup `catch (ApiException e)` lalu tampilkan
/// `e.message` ke user (misalnya lewat dialog helper), tanpa perlu
/// tahu detail HTTP status code atau format JSON di baliknya.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
