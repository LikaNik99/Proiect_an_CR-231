import '../entities/teacher.dart';
import '../repositories/teacher_repository.dart';

class GetCurrentTeacherUseCase {
  final TeacherRepository repository;

  GetCurrentTeacherUseCase(this.repository);

  Future<Teacher> call(String token) {
    return repository.getCurrentTeacher(token);
  }
}
