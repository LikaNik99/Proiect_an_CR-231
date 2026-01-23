import '../entities/class_entity.dart';

abstract class ClassRepository {
  Future<List<ClassEntity>> getClasses();
  Future<ClassEntity?> getClass(String classId);
  Future<ClassEntity?> createClass(ClassEntity classEntity);
  Future<ClassEntity?> updateClass(String classId, ClassEntity classEntity);
  Future<bool> deleteClass(String classId);
}