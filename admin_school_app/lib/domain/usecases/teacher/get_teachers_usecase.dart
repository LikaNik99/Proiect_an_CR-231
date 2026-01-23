import '../../entities/teacher_entity.dart';
import '../../repositories/teacher_repository.dart';

class GetTeachersUseCase {
  final TeacherRepository repository;

  GetTeachersUseCase(this.repository);

  Future<List<TeacherEntity>> call() async {
    return await repository.getTeachers();
  }
}