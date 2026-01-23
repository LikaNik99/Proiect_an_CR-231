import '../../entities/student_entity.dart';
import '../../repositories/student_repository.dart';

class GetStudentsUseCase {
  final StudentRepository repository;

  GetStudentsUseCase(this.repository);

  Future<List<StudentEntity>> call() async {
    return await repository.getStudents();
  }
}