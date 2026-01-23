import '../../repositories/class_repository.dart';

class DeleteClassUseCase {
  final ClassRepository repository;

  DeleteClassUseCase(this.repository);

  Future<bool> call(String classId) async {
    return await repository.deleteClass(classId);
  }
}