import 'package:get/get.dart';

class PasswordController extends GetxController {



  var isLoading = false.obs;
  var message = ''.obs;

  Future<void> sendResetCode(String email) async {
    try {
      isLoading.value = true;


      message.value = 'Codul a fost trimis';
    } catch (e) {
      message.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email, int code, String password) async {


  }

  Future<void> sendActivationCode(String email) async {


  }

  Future<void> setPassword(String email, int code, String password) async {


  }
}
