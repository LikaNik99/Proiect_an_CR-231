import '../../entities/student_entity.dart';
import '../../repositories/student_repository.dart';

class GetStudentUseCase {
  final StudentRepository repository;

  GetStudentUseCase(this.repository);

  Future<StudentEntity?> call(String studentId) async {
    return await repository.getStudent(studentId);
  }
}