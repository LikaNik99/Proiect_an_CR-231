import '../../domain/entities/teacher_entity.dart';
import '../../domain/entities/teacher_upsert_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../data_sources/teacher_data_source.dart';
import '../models/teacher_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherDataSource dataSource;

  TeacherRepositoryImpl(this.dataSource);

  @override
  Future<List<TeacherEntity>> getTeachers() async {
    return await dataSource.getTeachers();
  }

  @override
  Future<TeacherEntity?> getTeacher(String teacherId) async {
    return await dataSource.getTeacher(teacherId);
  }

  @override
  Future<TeacherEntity?> createTeacher(TeacherUpsertEntity teacher) async {

    final model = TeacherModel(
      userId: teacher.userId ?? '',
      subject: teacher.subject,
      isDirector: teacher.isDirector,
      isHomeroom: teacher.isHomeroom,
      classId: teacher.classId,
      schoolId: teacher.schoolId,
    );
    return await dataSource.createTeacher(model, username: teacher.username, email: teacher.email);
  }

  @override
  Future<TeacherEntity?> updateTeacher(String teacherId, TeacherUpsertEntity teacher) async {
    final model = TeacherModel(
      userId: teacher.userId ?? teacherId,
      subject: teacher.subject,
      isDirector: teacher.isDirector,
      isHomeroom: teacher.isHomeroom,
      classId: teacher.classId,
      schoolId: teacher.schoolId,
    );
    return await dataSource.updateTeacher(teacherId, model, username: teacher.username, email: teacher.email);
  }

  @override
  Future<bool> deleteTeacher(String teacherId) async {
    return await dataSource.deleteTeacher(teacherId);
  }
}