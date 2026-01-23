import '../../entities/class_entity.dart';
import '../../repositories/class_repository.dart';

class UpdateClassUseCase {
  final ClassRepository repository;

  UpdateClassUseCase(this.repository);

  Future<ClassEntity?> call(String classId, ClassEntity classEntity) async {
    return await repository.updateClass(classId, classEntity);
  }
}