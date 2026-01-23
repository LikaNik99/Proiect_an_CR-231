import '../../repositories/student_repository.dart';

class DeleteStudentUseCase {
  final StudentRepository repository;

  DeleteStudentUseCase(this.repository);

  Future<bool> call(String studentId) async {
    return await repository.deleteStudent(studentId);
  }
}