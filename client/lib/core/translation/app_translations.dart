import 'package:get/get.dart';
import '../../features/student/student_translations.dart';
import '../../features/auth/auth_translations.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ro': {
          'welcome': 'Bine ai venit!',
          'subtitle': 'Aplicația ta preferată de gestionare școli',
          'login': 'Loghează-te',
          ...AuthTranslations.translations['ro']!,
          ...StudentTranslations.translations['ro']!,
        },
        'en': {
          'welcome': 'Welcome!',
          'subtitle': 'Your favorite school management app',
          'login': 'Login',
          ...AuthTranslations.translations['en']!,

          ...StudentTranslations.translations['en']!,
        },
        'ru': {
          'welcome': 'Добро пожаловать!',
          'subtitle': 'Ваш любимый менеджер школы',
          'login': 'Войти',
          ...AuthTranslations.translations['ru']!,

          ...StudentTranslations.translations['ru']!,
        },
      };
}
