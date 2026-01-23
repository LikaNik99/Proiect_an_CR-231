import '../entities/teacher_entity.dart';
import '../entities/teacher_upsert_entity.dart';

abstract class TeacherRepository {
  Future<List<TeacherEntity>> getTeachers();
  Future<TeacherEntity?> getTeacher(String teacherId);

  Future<TeacherEntity?> createTeacher(TeacherUpsertEntity teacher);
  Future<TeacherEntity?> updateTeacher(String teacherId, TeacherUpsertEntity teacher);

  Future<bool> deleteTeacher(String teacherId);
}