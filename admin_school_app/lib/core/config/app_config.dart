/// Application configuration for Admin App
/// Change these values based on your environment
class AppConfig {

  static const String devBaseUrl = 'http://172.18.22.164:8000';


  static const String prodBaseUrl = 'https://api.yourschoolapp.com';


  static const bool isProduction = false;


  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;


  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 6);


  static const Duration tokenRefreshThreshold = Duration(minutes: 5);


  static const String dbHost = '10.240.0.129';
  static const int dbPort = 5432;
  static const String dbName = 'school_db';
  static const String dbUser = 'postgres';
  static const String dbPassword = 'password';
  static const bool dbUseSSL = false;
}
