import 'package:get/get.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/dashboard/dashboard_page.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));


    final hasMigrated = await SecureStorageService.hasMigrated();

    if (!hasMigrated) {

      await SecureStorageService.deleteToken();
      await SecureStorageService.setMigrated();
      Get.offAll(() => const LoginPage());
      return;
    }


    final token = await SecureStorageService.getToken();

    if (token != null && token.isNotEmpty) {

      Get.offAll(() => const DashboardPage());
    } else {

      Get.offAll(() => const LoginPage());
    }
  }
}