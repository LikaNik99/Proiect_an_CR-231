import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/network/network_fallback.dart';
import '../../core/network/api_health_service.dart';
import 'db/auth_db_data_source.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> checkEmail(String email);

  Future<UserModel?> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final AuthDbDataSource dbDataSource;

  AuthRemoteDataSourceImpl(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = AuthDbDataSource(dbManager);

  @override
  Future<UserModel?> checkEmail(String email) async {
    final url = '/auth/check-email';
    final data = {'email': email};
    try {

      if (ApiHealthService.isApiDown) {
        return null;
      }
      final response = await dio.post(url, data: data);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
    } on DioException catch (_) {

    } catch (_) {}

    return null;
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final url = '/auth/login';
    final data = {'email': email, 'password': password};

    try {

      if (ApiHealthService.isApiDown) {
        return await dbDataSource.login(email, password);
      }

      final response = await dio.post(url, data: data);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        user.accessToken = response.data['access_token'];
        return user;
      }
    } on DioException catch (e) {
      if (NetworkFallback.shouldFallback(e)) {
        return await dbDataSource.login(email, password);
      }
    } catch (_) {}

    return null;
  }
}
