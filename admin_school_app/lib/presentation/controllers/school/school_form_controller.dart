import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/school_entity.dart';
import '../../../domain/usecases/school/create_school_usecase.dart';
import '../../../domain/usecases/school/update_school_usecase.dart';
import '../../../domain/usecases/school/get_school_usecase.dart';
import 'package:get_it/get_it.dart';

class SchoolFormController extends GetxController {
  final CreateSchoolUseCase createSchoolUseCase = GetIt.instance.get<CreateSchoolUseCase>();
  final UpdateSchoolUseCase updateSchoolUseCase = GetIt.instance.get<UpdateSchoolUseCase>();
  final GetSchoolUseCase getSchoolUseCase = GetIt.instance.get<GetSchoolUseCase>();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  final logoUrlController = TextEditingController();
  final establishedYearController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isEditMode = false.obs;
  var isActive = true.obs;
  String? schoolId;

  SchoolFormController({this.schoolId});

  @override
  void onInit() {
    super.onInit();
    if (schoolId != null) {
      isEditMode.value = true;
      loadSchool();
    }
  }

  Future<void> loadSchool() async {
    if (schoolId == null) return;

    isLoading.value = true;
    try {
      final school = await getSchoolUseCase(schoolId!);
      if (school != null) {
        nameController.text = school.name;
        locationController.text = school.location ?? '';
        phoneController.text = school.phone ?? '';
        emailController.text = school.email ?? '';
        websiteController.text = school.website ?? '';
        logoUrlController.text = school.logoUrl ?? '';
        establishedYearController.text = school.establishedYear?.toString() ?? '';
        isActive.value = school.isActive;
      }
    } catch (e) {
      errorMessage.value = 'Eroare la încărcarea școlii: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSchool() async {
    if (nameController.text.trim().isEmpty) {
      errorMessage.value = 'Introduceți numele școlii';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    int? establishedYear;
    if (establishedYearController.text.trim().isNotEmpty) {
      establishedYear = int.tryParse(establishedYearController.text.trim());
    }

    final school = SchoolEntity(
      id: schoolId,
      name: nameController.text.trim(),
      location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
      logoUrl: logoUrlController.text.trim().isEmpty ? null : logoUrlController.text.trim(),
      establishedYear: establishedYear,
      isActive: isActive.value,
    );

    try {
      SchoolEntity? result;
      if (isEditMode.value && schoolId != null) {
        result = await updateSchoolUseCase(schoolId!, school);
      } else {
        result = await createSchoolUseCase(school);
      }

      if (result != null) {
        Get.back(result: true);
        Get.snackbar(
          'Succes',
          isEditMode.value ? 'Școala a fost actualizată' : 'Școala a fost creată',
        );
      } else {
        errorMessage.value = 'Eroare la salvarea școlii';
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
    locationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    logoUrlController.dispose();
    establishedYearController.dispose();
    super.onClose();
  }
}