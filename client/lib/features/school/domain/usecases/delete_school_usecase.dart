import '../repositories/school_repository.dart';

class DeleteSchoolUseCase {
  final SchoolRepository repository;
  DeleteSchoolUseCase(this.repository);

  Future<bool> call(String id, String token) async {
    return await repository.deleteSchool(id, token);
  }
}
