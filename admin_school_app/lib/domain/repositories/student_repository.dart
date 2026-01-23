import '../entities/student_entity.dart';
import '../entities/student_upsert_entity.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getStudents();
  Future<StudentEntity?> getStudent(String studentId);

  Future<StudentEntity?> createStudent(StudentUpsertEntity student);
  Future<StudentEntity?> updateStudent(String studentId, StudentUpsertEntity student);

  Future<bool> deleteStudent(String studentId);
}