import 'package:dio/dio.dart';
import '../models/password_model.dart';

abstract class PasswordDataSource {
  Future<void> sendResetCode(String email);

  Future<void> resetPassword(String email, int code, String password);

  Future<void> sendActivationCode(String email);

  Future<void> setPassword(String email, int code, String password);
}

class PasswordDataSourceImpl implements PasswordDataSource {
  final Dio dio;

  PasswordDataSourceImpl(this.dio);

  @override
  Future<void> sendResetCode(String email) async {
    final model = PasswordModel(email: email);
    await dio.post('/password/send-code', data: model.toJson());
  }

  @override
  Future<void> resetPassword(String email, int code, String password) async {
    final model = PasswordModel(email: email, code: code, password: password);
    await dio.post('/password/reset', data: model.toJson());
  }

  @override
  Future<void> sendActivationCode(String email) async {
    final model = PasswordModel(email: email);
    await dio.post('/password/send-activation-code', data: model.toJson());
  }

  @override
  Future<void> setPassword(String email, int code, String password) async {
    final model = PasswordModel(email: email, code: code, password: password);
    await dio.post('/password/set-password', data: model.toJson());
  }
}
