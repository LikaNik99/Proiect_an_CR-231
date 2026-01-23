import '../repositories/password_repositories.dart';
import '../../domain/entities/password_entity.dart';

class SendResetCodeUseCase {
  final PasswordRepository repository;

  SendResetCodeUseCase(this.repository);

  Future<void> call(PasswordEntity password) async {
    return repository.sendResetCode(password);
  }
}

class ResetPasswordUseCase {
  final PasswordRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> call(PasswordEntity password) async {
    return repository.resetPassword(password);
  }
}

class SendActivationCodeUseCase {
  final PasswordRepository repository;

  SendActivationCodeUseCase(this.repository);

  Future<void> call(PasswordEntity password) async {
    return repository.sendActivationCode(password);
  }
}

class SetPasswordUseCase {
  final PasswordRepository repository;

  SetPasswordUseCase(this.repository);

  Future<void> call(PasswordEntity password) async {
    return repository.setPassword(password);
  }
}
