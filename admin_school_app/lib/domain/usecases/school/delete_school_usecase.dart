import '../../repositories/school_repository.dart';

class DeleteSchoolUseCase {
  final SchoolRepository repository;

  DeleteSchoolUseCase(this.repository);

  Future<bool> call(String schoolId) async {
    return await repository.deleteSchool(schoolId);
  }
}