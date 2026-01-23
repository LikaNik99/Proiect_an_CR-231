import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection.dart';
import 'core/translation/app_translations.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/cache_service.dart';
import 'features/auth/domain/entities/USER_ROLE.dart';
import 'features/student/presentation/pages/student_dashboard_page.dart';
import 'features/teacher/presentation/pages/teacher_page.dart';
import 'welcome_page.dart';
import 'core/widgets/connection_status_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Future.wait([
    initDependencies(),
    CacheService.init(),
  ]);


  final savedLang = await SecureStorageService.getLanguage();
  final localeCode = savedLang ?? 'ro';


  await initializeDateFormatting(localeCode, null);

  final token = await SecureStorageService.getToken();
  debugPrint("App started, token exists: ${token != null}");

  final roleString = await SecureStorageService.getRole();


  Widget initialPage = const WelcomePage();

  if (token != null && roleString != null) {
    try {
      final role = UserRoleExtension.fromString(roleString);
      switch (role) {
        case UserRole.teacher:
          initialPage = TeacherDashboardPage();
          break;
        case UserRole.student:
          initialPage = const StudentDashboardPage();
          break;
      }
    } catch (e) {
      await SecureStorageService.deleteToken();
    }
  }

  runApp(MyApp(initialPage: initialPage, initialLocaleCode: localeCode));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  final String initialLocaleCode;

  const MyApp({super.key, required this.initialPage, required this.initialLocaleCode});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: Locale(initialLocaleCode),
      fallbackLocale: const Locale('en', 'US'),
      home: Stack(
        children: [
          initialPage,

          Align(
            alignment: Alignment.topCenter,
            child: ConnectionStatusBar(),
          ),
        ],
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
