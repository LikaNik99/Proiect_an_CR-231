import 'package:get/get.dart';
import '../../../domain/entities/class_entity.dart';
import '../../../domain/usecases/class/get_classes_usecase.dart';
import '../../../domain/usecases/class/delete_class_usecase.dart';
import '../../../core/database/db_error_mapper.dart';
import 'package:get_it/get_it.dart';

class ClassesController extends GetxController {
  final GetClassesUseCase getClassesUseCase = GetIt.instance.get<GetClassesUseCase>();
  final DeleteClassUseCase deleteClassUseCase = GetIt.instance.get<DeleteClassUseCase>();

  var classes = <ClassEntity>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }

  Future<void> loadClasses() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await getClassesUseCase();
      classes.value = result;
    } catch (e) {
      errorMessage.value = DbErrorMapper.toUserMessage(e is Object ? e : Exception('Unknown error'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      final success = await deleteClassUseCase(classId);
      if (success) {
        classes.removeWhere((c) => c.id == classId);
        Get.snackbar('Succes', 'Clasa a fost ștearsă');
      } else {
        Get.snackbar('Eroare', 'Nu s-a putut șterge clasa');
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la ștergerea clasei: $e');
    }
  }
}