import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/class_repository.dart';
import '../data_sources/class_data_source.dart';
import '../models/class_model.dart';

class ClassRepositoryImpl implements ClassRepository {
  final ClassDataSource dataSource;

  ClassRepositoryImpl(this.dataSource);

  @override
  Future<List<ClassEntity>> getClasses() async {
    return await dataSource.getClasses();
  }

  @override
  Future<ClassEntity?> getClass(String classId) async {
    return await dataSource.getClass(classId);
  }

  @override
  Future<ClassEntity?> createClass(ClassEntity classEntity) async {
    final model = ClassModel(
      id: classEntity.id,
      name: classEntity.name,
      teacherId: classEntity.teacherId,
      schoolId: classEntity.schoolId,
    );
    return await dataSource.createClass(model);
  }

  @override
  Future<ClassEntity?> updateClass(String classId, ClassEntity classEntity) async {
    final model = ClassModel(
      id: classEntity.id,
      name: classEntity.name,
      teacherId: classEntity.teacherId,
      schoolId: classEntity.schoolId,
    );
    return await dataSource.updateClass(classId, model);
  }

  @override
  Future<bool> deleteClass(String classId) async {
    return await dataSource.deleteClass(classId);
  }
}