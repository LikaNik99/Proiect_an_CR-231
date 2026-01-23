import '../entities/password_entity.dart';

abstract class PasswordRepository {
  Future<void> sendResetCode(PasswordEntity password);
  Future<void> resetPassword(PasswordEntity password);
  Future<void> sendActivationCode(PasswordEntity password);
  Future<void> setPassword(PasswordEntity password);
}
