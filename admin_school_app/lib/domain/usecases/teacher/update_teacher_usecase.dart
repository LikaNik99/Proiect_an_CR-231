import '../../entities/teacher_entity.dart';
import '../../entities/teacher_upsert_entity.dart';
import '../../repositories/teacher_repository.dart';

class UpdateTeacherUseCase {
  final TeacherRepository repository;

  UpdateTeacherUseCase(this.repository);

  Future<TeacherEntity?> call(String teacherId, TeacherUpsertEntity teacher) async {
    return await repository.updateTeacher(teacherId, teacher);
  }
}