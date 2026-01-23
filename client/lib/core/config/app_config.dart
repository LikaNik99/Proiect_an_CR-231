class AppConfig {

  static const String devBaseUrl = 'http://172.18.22.164:8000';


  static const String prodBaseUrl = 'https://api.yourschoolapp.com';


  static const bool isProduction = false;


  static String get baseUrl => devBaseUrl;


  static const Duration connectTimeout = Duration(seconds: 4);
  static const Duration receiveTimeout = Duration(seconds: 6);


  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
