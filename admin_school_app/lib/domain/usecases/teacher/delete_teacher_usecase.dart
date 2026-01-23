import '../../repositories/teacher_repository.dart';

class DeleteTeacherUseCase {
  final TeacherRepository repository;

  DeleteTeacherUseCase(this.repository);

  Future<bool> call(String teacherId) async {
    return await repository.deleteTeacher(teacherId);
  }
}