import '../../entities/student_entity.dart';
import '../../entities/student_upsert_entity.dart';
import '../../repositories/student_repository.dart';

class CreateStudentUseCase {
  final StudentRepository repository;

  CreateStudentUseCase(this.repository);

  Future<StudentEntity?> call(StudentUpsertEntity student) async {
    return await repository.createStudent(student);
  }
}