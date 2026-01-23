import 'package:dio/dio.dart';
import '../../../users/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> checkEmail(String email);

  Future<UserModel?> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel?> checkEmail(String email) async {
    final url = '/auth/check-email';
    final data = {'email': email};
    try {
      final response = await dio.post(url, data: data);
      if (response.statusCode == 200) {
        print('response: ${response.data}');
        return UserModel.fromJson(response.data);
      } else {}
    } on DioException catch (e) {
      if (e.response != null) {}
    } catch (e) {}

    return null;
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final url = '/auth/login';
    final data = {'email': email, 'password': password};

    try {
      final response = await dio.post(url, data: data);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        user.accessToken = response.data['access_token'] ?? '';
        user.refreshToken = response.data['refresh_token'] ?? '';
        return user;
      }
    } on DioException catch (e) {
      print('Login error: ${e.response?.data}');
    } catch (e) {
      print('Login error: $e');
    }

    return null;
  }
}
