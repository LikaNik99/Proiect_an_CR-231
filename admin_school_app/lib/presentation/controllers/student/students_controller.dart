import 'package:get/get.dart';
import '../../../domain/entities/student_entity.dart';
import '../../../domain/entities/school_entity.dart';
import '../../../domain/entities/class_entity.dart';
import '../../../domain/usecases/student/get_students_usecase.dart';
import '../../../domain/usecases/student/delete_student_usecase.dart';
import '../../../domain/usecases/school/get_schools_usecase.dart';
import '../../../domain/usecases/class/get_classes_usecase.dart';
import '../../../core/database/db_error_mapper.dart';
import 'package:get_it/get_it.dart';

class StudentsController extends GetxController {
  final GetStudentsUseCase getStudentsUseCase = GetIt.instance.get<GetStudentsUseCase>();
  final DeleteStudentUseCase deleteStudentUseCase = GetIt.instance.get<DeleteStudentUseCase>();
  final GetSchoolsUseCase getSchoolsUseCase = GetIt.instance.get<GetSchoolsUseCase>();
  final GetClassesUseCase getClassesUseCase = GetIt.instance.get<GetClassesUseCase>();

  var students = <StudentEntity>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final _schoolNameById = <String, String>{}.obs;
  final _classNameById = <String, String>{}.obs;
  final _classSchoolIdByClassId = <String, String?>{}.obs;

  String schoolNameFor(String? schoolId) {
    if (schoolId == null || schoolId.isEmpty) return '-';
    return _schoolNameById[schoolId] ?? schoolId;
  }

  String classNameFor(String? classId) {
    if (classId == null || classId.isEmpty) return '-';
    return _classNameById[classId] ?? classId;
  }

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> _loadIndexes() async {
    try {
      final schools = await getSchoolsUseCase();
      final smap = <String, String>{};
      for (final SchoolEntity s in schools) {
        if (s.id != null) smap[s.id!] = s.name;
      }
      _schoolNameById.value = smap;
    } catch (_) {}

    try {
      final classes = await getClassesUseCase();
      final cmap = <String, String>{};
      final cSchool = <String, String?>{};
      for (final ClassEntity c in classes) {
        if (c.id != null) {
          cmap[c.id!] = c.name;
          cSchool[c.id!] = c.schoolId;
        }
      }
      _classNameById.value = cmap;
      _classSchoolIdByClassId.value = cSchool;
    } catch (_) {}
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadIndexes();
      final result = await getStudentsUseCase();

      students.value = result
          .map((s) {
            final schoolId = s.user?.schoolId ?? _classSchoolIdByClassId[s.classId ?? ''];
            return StudentEntity(
              userId: s.userId,
              classId: s.classId,
              user: s.user,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
              className: s.className ?? classNameFor(s.classId),
              schoolName: s.schoolName ?? schoolNameFor(schoolId),
            );
          })
          .toList();
    } catch (e) {
      errorMessage.value = DbErrorMapper.toUserMessage(e is Object ? e : Exception('Unknown error'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteStudent(String studentUserId) async {
    try {
      final success = await deleteStudentUseCase(studentUserId);
      if (success) {
        students.removeWhere((student) => student.userId == studentUserId);
        Get.snackbar('Succes', 'Elevul a fost șters');
      } else {
        Get.snackbar('Eroare', 'Nu s-a putut șterge elevul');
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la ștergerea elevului: $e');
    }
  }
}