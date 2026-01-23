import 'package:dio/dio.dart';

class AuthOptions {
  static Options bearer(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
