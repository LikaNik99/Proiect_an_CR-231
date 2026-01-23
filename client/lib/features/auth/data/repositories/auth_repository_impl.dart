import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> checkEmail(String email) async {
    return await remoteDataSource.checkEmail(email);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

}
