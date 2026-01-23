import '../../entities/teacher_entity.dart';
import '../../repositories/teacher_repository.dart';

class GetTeacherUseCase {
  final TeacherRepository repository;

  GetTeacherUseCase(this.repository);

  Future<TeacherEntity?> call(String teacherId) async {
    return await repository.getTeacher(teacherId);
  }
}