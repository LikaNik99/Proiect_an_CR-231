import 'package:get/get.dart';
import '../../../domain/entities/teacher_entity.dart';
import '../../../domain/entities/school_entity.dart';
import '../../../domain/usecases/teacher/get_teachers_usecase.dart';
import '../../../domain/usecases/teacher/delete_teacher_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../core/database/db_error_mapper.dart';
import 'package:get_it/get_it.dart';

class TeachersController extends GetxController {
  final GetTeachersUseCase getTeachersUseCase = GetIt.instance.get<GetTeachersUseCase>();
  final DeleteTeacherUseCase deleteTeacherUseCase = GetIt.instance.get<DeleteTeacherUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();

  var teachers = <TeacherEntity>[].obs;
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
    loadTeachers();
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

  Future<void> loadTeachers() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadSchoolsIndex();
      final result = await getTeachersUseCase();

      teachers.value = result
          .map(
            (t) => TeacherEntity(
              userId: t.userId,
              subject: t.subject,
              isDirector: t.isDirector,
              isHomeroom: t.isHomeroom,
              classId: t.classId,
              schoolId: t.schoolId,
              user: t.user,
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
              schoolName: t.schoolName ?? schoolNameFor(t.schoolId),
            ),
          )
          .toList();
    } catch (e) {
      errorMessage.value = DbErrorMapper.toUserMessage(e is Object ? e : Exception('Unknown error'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTeacher(String teacherUserId) async {
    try {
      final success = await deleteTeacherUseCase(teacherUserId);
      if (success) {
        teachers.removeWhere((teacher) => teacher.userId == teacherUserId);
        Get.snackbar('Succes', 'Profesorul a fost șters');
      } else {
        Get.snackbar('Eroare', 'Nu s-a putut șterge profesorul');
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la ștergerea profesorului: $e');
    }
  }
}