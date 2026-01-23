import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasource/teacher_remote_data_source.dart';
import '../model/teacher_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource remoteDataSource;

  TeacherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Teacher> getCurrentTeacher(String token) async {
    return await remoteDataSource.getCurrentTeacher(token);
  }

  @override
  Future<String> uploadAvatar(String userId, String token, String filePath) async {
    return await remoteDataSource.uploadAvatar(userId, token, filePath);
  }
}
