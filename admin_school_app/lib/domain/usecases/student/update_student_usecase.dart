import '../../entities/student_entity.dart';
import '../../entities/student_upsert_entity.dart';
import '../../repositories/student_repository.dart';

class UpdateStudentUseCase {
  final StudentRepository repository;

  UpdateStudentUseCase(this.repository);

  Future<StudentEntity?> call(String studentId, StudentUpsertEntity student) async {
    return await repository.updateStudent(studentId, student);
  }
}