class api_config{
  // static const String BASE_URL = "http://api-presensi-berkah.infinityfreeapp.com/";
  static const String BASE_URL = "http://192.168.137.25/API_Absensi";
  static const String loginEndpoint = '$BASE_URL/auth/login';
  
  // Kunci untuk menyimpan token di local storage
  static const String tokenKey = 'USER_AUTH_TOKEN';
}