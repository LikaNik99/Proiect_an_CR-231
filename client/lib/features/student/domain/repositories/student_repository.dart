import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<List<Student>> getAll();

  Future<Student> getById(String id);

  Future<Student> create(Student student);

  Future<Student> update(String id, Student student);

  Future<void> delete(String id);
}
