import 'package:get/get.dart';
import '../../domain/usecases/send_reset_code_usecase.dart';
import '../../domain/entities/password_entity.dart';

class PasswordController extends GetxController {
  final SendResetCodeUseCase sendResetCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SendActivationCodeUseCase sendActivationCodeUseCase;
  final SetPasswordUseCase setPasswordUseCase;

  PasswordController({
    required this.sendResetCodeUseCase,
    required this.resetPasswordUseCase,
    required this.sendActivationCodeUseCase,
    required this.setPasswordUseCase,
  });

  var isLoading = false.obs;
  var message = ''.obs;

  Future<void> sendResetCode(String email) async {
    try {
      isLoading.value = true;
      final entity = PasswordEntity(email: email);
      await sendResetCodeUseCase(entity);
      message.value = 'Codul a fost trimis';
    } catch (e) {
      message.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email, int code, String password) async {
    try {
      isLoading.value = true;
      final entity = PasswordEntity(
        email: email,
        code: code,
        password: password,
      );
      await resetPasswordUseCase(entity);
      message.value = 'Parola a fost resetată';
    } catch (e) {
      message.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendActivationCode(String email) async {
    try {
      isLoading.value = true;
      final entity = PasswordEntity(email: email);
      await sendActivationCodeUseCase(entity);
      message.value = 'Codul pentru activare a fost trimis';
    } catch (e) {
      message.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setPassword(String email, int code, String password) async {
    try {
      isLoading.value = true;
      final entity = PasswordEntity(
        email: email,
        code: code,
        password: password,
      );
      await setPasswordUseCase(entity);
      message.value = 'Parola a fost setată și contul activat';
    } catch (e) {
      message.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
