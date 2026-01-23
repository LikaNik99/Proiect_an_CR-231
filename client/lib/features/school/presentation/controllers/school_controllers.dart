import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/school.dart';
import '../../domain/usecases/get_schools_usecase.dart';
import '../../domain/usecases/create_school_usecase.dart';
import '../../domain/usecases/update_school_usecase.dart';
import '../../domain/usecases/delete_school_usecase.dart';

class SchoolController extends GetxController {
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();
  final CreateSchoolUseCase createSchoolUseCase = GetIt.instance.get<CreateSchoolUseCase>();
  final UpdateSchoolUseCase updateSchoolUseCase = GetIt.instance.get<UpdateSchoolUseCase>();
  final DeleteSchoolUseCase deleteSchoolUseCase = GetIt.instance.get<DeleteSchoolUseCase>();

  final RxList<School> schools = <School>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;


  Future<void> getSchools({String? query}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Token not found';
        return;
      }

      final result = await getSchoolsUseCase.call(token);

      if (result.isNotEmpty) {
        if (query != null && query.trim().isNotEmpty) {
          final q = query.toLowerCase();
          final filtered = result.where((s) {
            final name = s.name.toLowerCase() ?? '';
            final location = s.location.toLowerCase() ?? '';
            final email = (s.email ?? '').toLowerCase();
            return name.contains(q) || location.contains(q) || email.contains(q);
          }).toList();
          schools.assignAll(filtered);
        } else {
          schools.assignAll(result);
        }
      } else {
        schools.clear();
        errorMessage.value = 'No schools found';
      }
    } catch (e) {
      errorMessage.value = 'Error loading schools: $e';
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> createSchool(School school) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Token not found';
        return;
      }

      final created = await createSchoolUseCase.call(school, token);
      if (created != null) {
        await getSchools();
      }
    } catch (e) {
      errorMessage.value = 'Error creating school: $e';
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> editSchool(String id, School school) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Token not found';
        return;
      }

      final updated = await updateSchoolUseCase.call(id, school, token);
      if (updated != null) {
        await getSchools();
      }
    } catch (e) {
      errorMessage.value = 'Error updating school: $e';
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> deleteSchool(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Token not found';
        return;
      }

      final deleted = await deleteSchoolUseCase.call(id, token);
      if (deleted) {
        await getSchools();
      } else {
        errorMessage.value = 'Delete failed';
      }
    } catch (e) {
      errorMessage.value = 'Error deleting school: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
