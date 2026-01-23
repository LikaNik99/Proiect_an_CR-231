import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../../../../core/ui/input_decorations.dart' as ui_decorations;
import '../../../domain/usecases/check_email_usecase.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../pages/dashboard/dashboard_page.dart';
import 'package:get_it/get_it.dart';

class LoginController extends GetxController {
  final CheckEmailUseCase checkEmailUseCase = GetIt.instance
      .get<CheckEmailUseCase>();
  final LoginUseCase loginUseCase = GetIt.instance.get<LoginUseCase>();

  final _emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  var email = ''.obs;
  var password = ''.obs;
  var showPasswordField = false.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isPasswordHidden = true.obs;

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return ui_decorations.buildInputDecoration(
      label: label,
      icon: icon,
      hint: hint,
      fillColor: const Color(0xFF23232E),
      borderColor: Colors.white10,
      focusedColor: Colors.indigo.shade300,
    );
  }

  InputDecoration emailDecoration({String? hint}) {
    return buildInputDecoration(
      label: 'email_label'.tr,
      icon: Icons.email,
      hint: hint,
    );
  }

  InputDecoration passwordDecoration({String? hint}) {
    return buildInputDecoration(
      label: 'password_label'.tr,
      icon: Icons.lock,
      hint: hint,
    );
  }

  var activationStep = 0.obs;
  var activationLoading = false.obs;
  var sentCode = ''.obs;

  Future<void> sendActivationCode(String emailValue) async {
    final e = emailValue.trim();
    if (e.isEmpty || !_emailRegex.hasMatch(e)) {
      errorMessage.value = 'Introduceți un email valid';
      return;
    }
    activationLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    sentCode.value = code;
    activationStep.value = 1;
    activationLoading.value = false;
    Get.snackbar(
      'Cod trimis',
      'Cod (dev): $code',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<bool> verifyActivationCode(String code) async {
    activationLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    final ok = code.trim() == sentCode.value;
    activationLoading.value = false;
    if (ok) {
      activationStep.value = 2;
    }
    return ok;
  }

  Future<bool> setNewPassword(String passwordValue) async {
    if (passwordValue.length < 6) {
      errorMessage.value = 'Parola trebuie să aibă minim 6 caractere';
      return false;
    }
    activationLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    activationLoading.value = false;
    activationStep.value = 0;
    sentCode.value = '';
    Get.snackbar(
      'Succes',
      'Contul a fost activat. Te poți autentifica acum.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  Future<dynamic> onCheckEmail() async {
    final e = email.value.trim();
    if (e.isEmpty || !_emailRegex.hasMatch(e)) {
      errorMessage.value = 'Introduceți un email valid';
      return null;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final user = await checkEmailUseCase(email.value);
    isLoading.value = false;

    if (user == null) {
      errorMessage.value = 'Emailul nu există!';
      return null;
    }
    if (user.exists == false) {
      errorMessage.value = 'Cont-ul nu există!';
      return null;
    }

    if (user.isActive == true) {
      showPasswordField.value = true;
    }

    return user;
  }

  Future<void> onLogin() async {
    final e = email.value.trim();
    if (e.isEmpty || !_emailRegex.hasMatch(e)) {
      errorMessage.value = 'Introduceți un email valid';
      return;
    }
    if (password.value.isEmpty) {
      errorMessage.value = 'Introduceți parola';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final authResponse = await loginUseCase(email.value, password.value);
    isLoading.value = false;

    if (authResponse == null) {
      errorMessage.value = 'Parolă incorectă!';
      return;
    }

    await SecureStorageService.saveToken(
      authResponse.accessToken,
      authResponse.role,
      authResponse.userId,
    );

    Get.offAll(() => const DashboardPage());
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void onForgotPassword() {
    Get.snackbar('Resetare parolă', 'Funcționalitate în dezvoltare');
  }
}
