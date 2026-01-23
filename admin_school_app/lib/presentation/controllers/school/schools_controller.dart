import 'package:get/get.dart';
import '../../../domain/entities/school_entity.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../domain/usecases/school/delete_school_usecase.dart';
import '../../../core/database/db_error_mapper.dart';
import 'package:get_it/get_it.dart';

class SchoolsController extends GetxController {
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();
  final DeleteSchoolUseCase deleteSchoolUseCase = GetIt.instance.get<DeleteSchoolUseCase>();

  var schools = <SchoolEntity>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSchools();
  }

  Future<void> loadSchools() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await getSchoolsUseCase();
      schools.value = result;
    } catch (e) {
      errorMessage.value = DbErrorMapper.toUserMessage(e is Object ? e : Exception('Unknown error'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSchool(String schoolId) async {
    try {
      final success = await deleteSchoolUseCase(schoolId);
      if (success) {
        schools.removeWhere((school) => school.id == schoolId);
        Get.snackbar('Succes', 'Școala a fost ștearsă');
      } else {
        Get.snackbar('Eroare', 'Nu s-a putut șterge școala');
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la ștergerea școlii: $e');
    }
  }
}