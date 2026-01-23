import '../../domain/entities/password_entity.dart';
import '../../domain/repositories/password_repositories.dart';
import '../datasource/password_data_source.dart';

class PasswordRepositoryImpl implements PasswordRepository {
  final PasswordDataSource dataSource;

  PasswordRepositoryImpl(this.dataSource);

  @override
  Future<void> sendResetCode(PasswordEntity password) async {
    return dataSource.sendResetCode(password.email);
  }

  @override
  Future<void> resetPassword(PasswordEntity password) async {
    return dataSource.resetPassword(
      password.email,
      password.code!,
      password.password!,
    );
  }

  @override
  Future<void> sendActivationCode(PasswordEntity password) async {
    return dataSource.sendActivationCode(password.email);
  }

  @override
  Future<void> setPassword(PasswordEntity password) async {
    return dataSource.setPassword(
      password.email,
      password.code!,
      password.password!,
    );
  }
}
