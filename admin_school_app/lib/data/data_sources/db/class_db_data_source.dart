import '../../models/class_model.dart';
import '../../../core/database/database_connection_manager.dart';

/// Direct DB datasource for classes (PostgreSQL)
class ClassDbDataSource {
  final DatabaseConnectionManager db;

  ClassDbDataSource(this.db);

  Future<List<ClassModel>> getClasses() async {
    final rows = await db.query('''
      SELECT id, name, school_id, teacher_id, created_at, updated_at
      FROM classes
      ORDER BY created_at DESC
    ''');

    return rows.map((r) => ClassModel.fromJson(r)).toList();
  }

  Future<ClassModel?> getClass(String id) async {
    final rows = await db.query('''
      SELECT id, name, school_id, teacher_id, created_at, updated_at
      FROM classes
      WHERE id = @0
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    return ClassModel.fromJson(rows.first);
  }

  Future<ClassModel?> createClass(ClassModel c) async {
    final id = c.id;
    if (id == null || id.isEmpty) {
      throw Exception('Class.id is required for direct DB create');
    }

    await db.execute('''
      INSERT INTO classes (id, name, school_id, teacher_id, created_at, updated_at)
      VALUES (@0, @1, @2, @3, NOW(), NOW())
    ''', [id, c.name, c.schoolId, c.teacherId]);

    return getClass(id);
  }

  Future<ClassModel?> updateClass(String id, ClassModel c) async {
    await db.execute('''
      UPDATE classes
      SET name=@0,
          school_id=@1,
          teacher_id=@2,
          updated_at=NOW()
      WHERE id=@3
    ''', [c.name, c.schoolId, c.teacherId, id]);

    return getClass(id);
  }

  Future<bool> deleteClass(String id) async {
    final affected = await db.execute('DELETE FROM classes WHERE id = @0', [id]);
    return affected > 0;
  }
}
