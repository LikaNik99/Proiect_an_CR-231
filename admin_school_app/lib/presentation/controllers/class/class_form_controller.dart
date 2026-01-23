import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/class_entity.dart';
import '../../../domain/usecases/class/create_class_usecase.dart';
import '../../../domain/usecases/class/update_class_usecase.dart';
import '../../../domain/usecases/class/get_class_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../domain/usecases/teacher/get_teachers_usecase.dart';
import '../../widgets/id_dropdown_field.dart';
import 'package:get_it/get_it.dart';

class ClassFormController extends GetxController {
  final CreateClassUseCase createClassUseCase = GetIt.instance.get<CreateClassUseCase>();
  final UpdateClassUseCase updateClassUseCase = GetIt.instance.get<UpdateClassUseCase>();
  final GetClassUseCase getClassUseCase = GetIt.instance.get<GetClassUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();
  final GetTeachersUseCase getTeachersUseCase = GetIt.instance.get<GetTeachersUseCase>();

  final nameController = TextEditingController();
  final teacherIdController = TextEditingController();
  final schoolIdController = TextEditingController();

  final schoolOptions = <IdDropdownOption>[].obs;
  final teacherOptions = <IdDropdownOption>[].obs;
  final isLoadingLookups = false.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isEditMode = false.obs;
  String? classId;

  ClassFormController({this.classId});

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
    if (classId != null) {
      isEditMode.value = true;
      loadClass();
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

      final teachers = await getTeachersUseCase();
      teacherOptions.value = teachers
          .map((t) => IdDropdownOption(
                id: t.userId,
                label: (t.user?.username?.isNotEmpty == true)
                    ? t.user!.username
                    : t.userId,
              ))
          .toList();
    } catch (_) {

    } finally {
      isLoadingLookups.value = false;
    }
  }

  void setSelectedSchoolId(String? id) {
    schoolIdController.text = id ?? '';
  }

  void setSelectedTeacherId(String? id) {
    teacherIdController.text = id ?? '';
  }

  Future<void> loadClass() async {
    if (classId == null) return;

    isLoading.value = true;
    try {
      final classEntity = await getClassUseCase(classId!);
      if (classEntity != null) {
        nameController.text = classEntity.name;
        teacherIdController.text = classEntity.teacherId?.toString() ?? '';
        schoolIdController.text = classEntity.schoolId.toString();
      }
    } catch (e) {
      errorMessage.value = 'Eroare la încărcarea clasei: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveClass() async {
    if (nameController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți numele clasei';
      return;
    }
    if (schoolIdController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți ID-ul școlii';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final classEntity = ClassEntity(
      id: classId,
      name: nameController.text.trim(),
      teacherId: teacherIdController.text.trim().isEmpty
          ? null
          : teacherIdController.text.trim(),
      schoolId: schoolIdController.text.trim(),
    );

    try {
      ClassEntity? result;
      if (isEditMode.value && classId != null) {
        result = await updateClassUseCase(classId!, classEntity);
      } else {
        result = await createClassUseCase(classEntity);
      }

      if (result != null) {
        Get.back(result: true);
        Get.snackbar(
          'Succes',
          isEditMode.value ? 'Clasa a fost actualizată' : 'Clasa a fost creată',
        );
      } else {
        errorMessage.value = 'Eroare la salvarea clasei';
      }
    } catch (e) {
      errorMessage.value = 'Eroare: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    teacherIdController.dispose();
    schoolIdController.dispose();
    super.onClose();
  }
}