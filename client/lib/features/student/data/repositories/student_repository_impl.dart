import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasource/student_remote_data_source.dart';
import '../model/student.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteDataSource remote;

  StudentRepositoryImpl(this.remote);

  @override
  Future<List<Student>> getAll() async {
    final students = await remote.getAll();
    return students;
  }

  @override
  Future<Student> getById(String id) => remote.getById(id);

  @override
  Future<Student> create(Student student) {
    return remote.create(student as StudentModel);
  }

  @override
  Future<Student> update(String id, Student student) {
    return remote.update(id, student as StudentModel);
  }

  @override
  Future<void> delete(String id) => remote.delete(id);
}
