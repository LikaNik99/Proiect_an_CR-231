import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/student_entity.dart';
import '../../domain/usecase/student_use_case.dart';

class StudentController extends GetxController {
  final StudentUseCase useCase;

  StudentController(this.useCase);

  var isLoading = false.obs;
  var students = <Student>[].obs;
  var errorMessage = "".obs;

  @override
  void onInit() {
    fetchStudents();
    super.onInit();
  }

  Future<void> fetchStudents() async {
    try {
      isLoading.value = true;
      final list = await useCase.getAll();
      students.value = list;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createStudent(Student student) async {
    await useCase.create(student);
    await fetchStudents();
  }

  Future<void> updateStudent(String id, Student student) async {
    await useCase.update(id, student);
    await fetchStudents();
  }

  Future<void> deleteStudent(String id) async {
    await useCase.delete(id);
    await fetchStudents();
  }
}
