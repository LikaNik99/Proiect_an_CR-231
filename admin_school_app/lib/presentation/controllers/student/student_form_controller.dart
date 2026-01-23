import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/student_upsert_entity.dart';
import '../../../domain/usecases/student/create_student_usecase.dart';
import '../../../domain/usecases/student/update_student_usecase.dart';
import '../../../domain/usecases/student/get_student_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../domain/usecases/class/get_classes_usecase.dart';
import '../../widgets/id_dropdown_field.dart';
import 'package:get_it/get_it.dart';

class StudentFormController extends GetxController {
  final CreateStudentUseCase createStudentUseCase = GetIt.instance.get<CreateStudentUseCase>();
  final UpdateStudentUseCase updateStudentUseCase = GetIt.instance.get<UpdateStudentUseCase>();
  final GetStudentUseCase getStudentUseCase = GetIt.instance.get<GetStudentUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();
  final GetClassesUseCase getClassesUseCase = GetIt.instance.get<GetClassesUseCase>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final classIdController = TextEditingController();
  final schoolIdController = TextEditingController();

  final schoolOptions = <IdDropdownOption>[].obs;
  final classOptions = <IdDropdownOption>[].obs;
  final isLoadingLookups = false.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isEditMode = false.obs;
  String? studentId;

  StudentFormController({this.studentId});

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
    if (studentId != null) {
      isEditMode.value = true;
      loadStudent();
    }
  }

  Future<void> _loadLookups() async {
    isLoadingLookups.value = true;
    try {
      final schools = await getSchoolsUseCase();
      schoolOptions.value = schools
          .where((s) => s.id != null)
          .map((s) => IdDropdownOption(id: s.id!, label: s.name))
          .toList();

      final classes = await getClassesUseCase();
      classOptions.value = classes
          .where((c) => c.id != null)
          .map((c) => IdDropdownOption(id: c.id!, label: c.name))
          .toList();
    } catch (_) {

    } finally {
      isLoadingLookups.value = false;
    }
  }

  void setSelectedSchoolId(String? id) {
    schoolIdController.text = id ?? '';
  }

  void setSelectedClassId(String? id) {
    classIdController.text = id ?? '';
  }

  Future<void> loadStudent() async {
    if (studentId == null) return;

    isLoading.value = true;
    try {
      final student = await getStudentUseCase(studentId!);
      if (student != null) {
        usernameController.text = student.user?.username ?? '';
        emailController.text = student.user?.email ?? '';
        classIdController.text = student.classId ?? '';

        schoolIdController.text = student.user?.schoolId ?? '';
      }
    } catch (e) {
      errorMessage.value = 'Eroare la încărcarea elevului: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveStudent() async {
    if (usernameController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți username-ul';
      return;
    }
    if (emailController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți email-ul';
      return;
    }
    if (classIdController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți ID-ul clasei';
      return;
    }
    if (schoolIdController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți ID-ul școlii';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final student = StudentUpsertEntity(
      userId: studentId,
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      classId: classIdController.text.trim(),
      schoolId: schoolIdController.text.trim(),
    );

    try {
      final result = (isEditMode.value && studentId != null)
          ? await updateStudentUseCase(studentId!, student)
          : await createStudentUseCase(student);

      if (result != null) {
        Get.back(result: true);
        Get.snackbar('Succes', isEditMode.value ? 'Elevul a fost actualizat' : 'Elevul a fost creat');
      } else {
        errorMessage.value = 'Eroare la salvarea elevului';
      }
    } catch (e) {
      errorMessage.value = 'Eroare: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    classIdController.dispose();
    schoolIdController.dispose();
    super.onClose();
  }
}