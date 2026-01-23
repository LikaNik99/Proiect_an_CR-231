import '../../entities/class_entity.dart';
import '../../repositories/class_repository.dart';

class GetClassUseCase {
  final ClassRepository repository;

  GetClassUseCase(this.repository);

  Future<ClassEntity?> call(String classId) async {
    return await repository.getClass(classId);
  }
}