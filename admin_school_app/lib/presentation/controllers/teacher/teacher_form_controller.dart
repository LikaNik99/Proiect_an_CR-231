import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/teacher_upsert_entity.dart';
import '../../../domain/usecases/teacher/create_teacher_usecase.dart';
import '../../../domain/usecases/teacher/update_teacher_usecase.dart';
import '../../../domain/usecases/teacher/get_teacher_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../domain/usecases/class/get_classes_usecase.dart';
import '../../widgets/id_dropdown_field.dart';
import 'package:get_it/get_it.dart';

class TeacherFormController extends GetxController {
  final CreateTeacherUseCase createTeacherUseCase = GetIt.instance
      .get<CreateTeacherUseCase>();
  final UpdateTeacherUseCase updateTeacherUseCase = GetIt.instance
      .get<UpdateTeacherUseCase>();
  final GetTeacherUseCase getTeacherUseCase = GetIt.instance
      .get<GetTeacherUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance
      .get<GetSchoolsUseCase>();
  final GetClassesUseCase getClassesUseCase = GetIt.instance
      .get<GetClassesUseCase>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final subjectController = TextEditingController();
  final schoolIdController = TextEditingController();
  final classIdController = TextEditingController();

  final schoolOptions = <IdDropdownOption>[].obs;
  final classOptions = <IdDropdownOption>[].obs;
  final isLoadingLookups = false.obs;

  var isDirector = false.obs;
  var isHomeroom = false.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isEditMode = false.obs;
  String? teacherId;

  TeacherFormController({this.teacherId});

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
    if (teacherId != null) {
      isEditMode.value = true;
      loadTeacher();
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

  Future<void> loadTeacher() async {
    if (teacherId == null) return;

    isLoading.value = true;
    try {
      final teacher = await getTeacherUseCase(teacherId!);
      if (teacher != null) {
        usernameController.text = teacher.user?.username ?? '';
        emailController.text = teacher.user?.email ?? '';
        subjectController.text = teacher.subject ?? '';
        schoolIdController.text = teacher.schoolId ?? teacher.user?.schoolId ?? '';
        classIdController.text = teacher.classId ?? '';
        isDirector.value = teacher.isDirector;
        isHomeroom.value = teacher.isHomeroom;
      }
    } catch (e) {
      errorMessage.value = 'Eroare la încărcarea profesorului: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveTeacher() async {
    if (usernameController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți username-ul';
      return;
    }
    if (emailController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți email-ul';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final teacher = TeacherUpsertEntity(
      userId: teacherId,
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      subject: subjectController.text.trim().isEmpty ? null : subjectController.text.trim(),
      isDirector: isDirector.value,
      isHomeroom: isHomeroom.value,
      classId: classIdController.text.trim().isEmpty ? null : classIdController.text.trim(),
      schoolId: schoolIdController.text.trim().isEmpty ? null : schoolIdController.text.trim(),
    );

    try {
      final result = (isEditMode.value && teacherId != null)
          ? await updateTeacherUseCase(teacherId!, teacher)
          : await createTeacherUseCase(teacher);

      if (result != null) {
        Get.back(result: true);
        Get.snackbar('Succes', isEditMode.value ? 'Profesorul a fost actualizat' : 'Profesorul a fost creat');
      } else {
        errorMessage.value = 'Eroare la salvarea profesorului';
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
    subjectController.dispose();
    schoolIdController.dispose();
    classIdController.dispose();
    super.onClose();
  }
}
