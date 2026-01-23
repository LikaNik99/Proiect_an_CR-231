import '../../entities/class_entity.dart';
import '../../repositories/class_repository.dart';

class CreateClassUseCase {
  final ClassRepository repository;

  CreateClassUseCase(this.repository);

  Future<ClassEntity?> call(ClassEntity classEntity) async {
    return await repository.createClass(classEntity);
  }
}