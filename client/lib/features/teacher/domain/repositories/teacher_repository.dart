import '../entities/teacher.dart';

abstract class TeacherRepository {

  Future<Teacher> getCurrentTeacher(String token);
  Future<String> uploadAvatar(String userId, String token, String filePath);

}
