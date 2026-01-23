import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/model/teacher_model.dart';
import '../../domain/usecases/get_current_teacher.dart';
import '../../domain/entities/teacher.dart';
import '../../../student/data/model/student.dart';

class TeacherController extends GetxController {
  final GetCurrentTeacherUseCase getCurrentTeacherUseCase = GetIt.instance
      .get<GetCurrentTeacherUseCase>();
  final teacher = Rxn<Teacher>();
  final classes = <SchoolClass>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentTeacher();
  }

  Future<void> fetchCurrentTeacher() async {
    isLoading.value = true;

    try {
      final token = await SecureStorageService.getToken();
      if (token == null) {
        print('No token available');
        return;
      }

      final fetchedTeacher = await getCurrentTeacherUseCase.call(token);
      teacher.value = fetchedTeacher;
      classes.value = fetchedTeacher.classes!;
    } catch (e) {
      print('Error fetching teacher: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
