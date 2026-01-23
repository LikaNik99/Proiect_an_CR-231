import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/admin_user_entity.dart';
import '../../../domain/entities/school_entity.dart';
import '../../../domain/usecases/admin_user/get_users_usecase.dart';
import '../../../domain/usecases/admin_user/delete_user_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../core/database/db_error_mapper.dart';

class AdminUsersController extends GetxController {
  final GetUsersUseCase getUsersUseCase = GetIt.instance.get<GetUsersUseCase>();
  final DeleteUserUseCase deleteUserUseCase = GetIt.instance.get<DeleteUserUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();

  var users = <AdminUserEntity>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final _schoolNameById = <String, String>{}.obs;

  String schoolNameFor(String? schoolId) {
    if (schoolId == null || schoolId.isEmpty) return '-';
    return _schoolNameById[schoolId] ?? schoolId;
  }

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> _loadSchoolsIndex() async {
    try {
      final schools = await getSchoolsUseCase();
      final map = <String, String>{};
      for (final SchoolEntity s in schools) {
        if (s.id != null) map[s.id!] = s.name;
      }
      _schoolNameById.value = map;
    } catch (_) {

    }
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadSchoolsIndex();
      final result = await getUsersUseCase();
      users.value = result
          .map((u) => AdminUserEntity(
                id: u.id,
                username: u.username,
                email: u.email,
                role: u.role,
                isActivated: u.isActivated,
                schoolId: u.schoolId,
                schoolName: schoolNameFor(u.schoolId),
                createdAt: u.createdAt,
                updatedAt: u.updatedAt,
              ))
          .toList();
    } catch (e) {
      errorMessage.value = DbErrorMapper.toUserMessage(e is Object ? e : Exception('Unknown error'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final success = await deleteUserUseCase(userId);
      if (success) {
        users.removeWhere((user) => user.id == userId);
        Get.snackbar('Succes', 'Utilizatorul a fost șters');
      } else {
        Get.snackbar('Eroare', 'Nu s-a putut șterge utilizatorul');
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la ștergerea utilizatorului: $e');
    }
  }
}