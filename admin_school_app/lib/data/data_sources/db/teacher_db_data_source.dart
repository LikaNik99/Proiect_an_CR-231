import '../../models/teacher_model.dart';
import '../../../core/database/database_connection_manager.dart';

/// Direct DB datasource for teachers (PostgreSQL)
class TeacherDbDataSource {
  final DatabaseConnectionManager db;

  TeacherDbDataSource(this.db);

  Future<List<TeacherModel>> getTeachers() async {
    final rows = await db.query('''
      SELECT
        t.user_id,
        t.subject,
        t.is_homeroom,
        t.is_director,
        t.class_id,
        t.created_at,
        t.updated_at,
        u.username,
        u.email,
        u.school_id,
        s.name AS school_name
      FROM teachers t
      JOIN users u ON u.id = t.user_id
      LEFT JOIN schools s ON s.id = u.school_id
      ORDER BY t.created_at DESC
    ''');

    return rows.map((r) => TeacherModel.fromJson(r)).toList();
  }

  Future<TeacherModel?> getTeacher(String userId) async {
    final rows = await db.query('''
      SELECT
        t.user_id,
        t.subject,
        t.is_homeroom,
        t.is_director,
        t.class_id,
        t.created_at,
        t.updated_at,
        u.username,
        u.email,
        u.school_id,
        s.name AS school_name
      FROM teachers t
      JOIN users u ON u.id = t.user_id
      LEFT JOIN schools s ON s.id = u.school_id
      WHERE t.user_id = @0
      LIMIT 1
    ''', [userId]);

    if (rows.isEmpty) return null;
    return TeacherModel.fromJson(rows.first);
  }

  /// Creates user + teacher row.
  /// Password is NOT created here; user must already exist OR you must use server.
  Future<TeacherModel?> upsertTeacher({
    required String username,
    required String email,
    String? schoolId,
    required String userId,
    String? subject,
    bool isHomeroom = false,
    bool isDirector = false,
    String? classId,
  }) async {

    await db.execute('''
      UPDATE users
      SET username = @0,
          email = @1,
          school_id = @2,
          updated_at = NOW()
      WHERE id = @3
    ''', [username, email, schoolId, userId]);


    await db.execute('''
      INSERT INTO teachers (user_id, subject, is_homeroom, is_director, class_id, created_at, updated_at)
      VALUES (@0, @1, @2, @3, @4, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE
      SET subject = EXCLUDED.subject,
          is_homeroom = EXCLUDED.is_homeroom,
          is_director = EXCLUDED.is_director,
          class_id = EXCLUDED.class_id,
          updated_at = NOW()
    ''', [userId, subject, isHomeroom, isDirector, classId]);

    return getTeacher(userId);
  }

  Future<bool> deleteTeacher(String userId) async {

    final affected = await db.execute('DELETE FROM teachers WHERE user_id = @0', [userId]);
    return affected > 0;
  }
}
