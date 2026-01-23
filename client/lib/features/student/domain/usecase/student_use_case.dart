import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class StudentUseCase {
  final StudentRepository repository;

  StudentUseCase(this.repository);

  Future<List<Student>> getAll() async {
    return await repository.getAll();
  }

  Future<Student> create(Student student) async {
    return await repository.create(student);
  }

  Future<Student> update(String id, Student student) async {
    return await repository.update(id, student);
  }

  Future<void> delete(String id) async {
    return await repository.delete(id);
  }
}
