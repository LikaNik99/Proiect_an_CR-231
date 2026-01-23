import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/admin_user_entity.dart';
import '../../../domain/usecases/admin_user/create_user_usecase.dart';
import '../../../domain/usecases/admin_user/update_user_usecase.dart';
import '../../../domain/usecases/admin_user/get_user_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../widgets/id_dropdown_field.dart';
import 'package:get_it/get_it.dart';

class AdminUserFormController extends GetxController {
  final CreateUserUseCase createUserUseCase = GetIt.instance.get<CreateUserUseCase>();
  final UpdateUserUseCase updateUserUseCase = GetIt.instance.get<UpdateUserUseCase>();
  final GetUserUseCase getUserUseCase = GetIt.instance.get<GetUserUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final roleController = TextEditingController();
  final schoolIdController = TextEditingController();

  final schoolOptions = <IdDropdownOption>[].obs;
  final isLoadingLookups = false.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isEditMode = false.obs;
  var isActivated = false.obs;
  String? userId;

  AdminUserFormController({this.userId});

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
    if (userId != null) {
      isEditMode.value = true;
      loadUser();
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
    } catch (_) {

    } finally {
      isLoadingLookups.value = false;
    }
  }

  void setSelectedSchoolId(String? id) {
    schoolIdController.text = id ?? '';
  }

  Future<void> loadUser() async {
    if (userId == null) return;

    isLoading.value = true;
    try {
      final user = await getUserUseCase(userId!);
      if (user != null) {
        usernameController.text = user.username;
        emailController.text = user.email;
        roleController.text = user.role;
        schoolIdController.text = user.schoolId ?? '';
        isActivated.value = user.isActivated;
      }
    } catch (e) {
      errorMessage.value = 'Eroare la încărcarea utilizatorului: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveUser() async {
    if (usernameController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți username-ul';
      return;
    }
    if (emailController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți email-ul';
      return;
    }
    if (roleController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți rolul';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final user = AdminUserEntity(
      id: userId,
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      role: roleController.text.trim(),
      isActivated: isActivated.value,
      schoolId: schoolIdController.text.trim().isEmpty ? null : schoolIdController.text.trim(),
    );

    try {
      AdminUserEntity? result;
      if (isEditMode.value && userId != null) {
        result = await updateUserUseCase(userId!, user);
      } else {
        result = await createUserUseCase(user);
      }

      if (result != null) {
        Get.back(result: true);
        Get.snackbar(
          'Succes',
          isEditMode.value ? 'Utilizatorul a fost actualizat' : 'Utilizatorul a fost creat',
        );
      } else {
        errorMessage.value = 'Eroare la salvarea utilizatorului';
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
    roleController.dispose();
    schoolIdController.dispose();
    super.onClose();
  }
}