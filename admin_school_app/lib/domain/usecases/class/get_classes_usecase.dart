import '../../entities/class_entity.dart';
import '../../repositories/class_repository.dart';

class GetClassesUseCase {
  final ClassRepository repository;

  GetClassesUseCase(this.repository);

  Future<List<ClassEntity>> call() async {
    return await repository.getClasses();
  }
}