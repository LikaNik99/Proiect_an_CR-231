import '../../models/student_model.dart';
import '../../../core/database/database_connection_manager.dart';

/// Direct DB datasource for students (PostgreSQL)
class StudentDbDataSource {
  final DatabaseConnectionManager db;

  StudentDbDataSource(this.db);

  Future<List<StudentModel>> getStudents() async {
    final rows = await db.query('''
      SELECT
        st.user_id,
        st.class_id,
        st.created_at,
        st.updated_at,
        u.username,
        u.email,
        u.school_id,
        sc.name AS school_name,
        c.name AS class_name
      FROM students st
      JOIN users u ON u.id = st.user_id
      LEFT JOIN schools sc ON sc.id = u.school_id
      LEFT JOIN classes c ON c.id = st.class_id
      ORDER BY st.created_at DESC
    ''');

    return rows.map((r) => StudentModel.fromJson(r)).toList();
  }

  Future<StudentModel?> getStudent(String userId) async {
    final rows = await db.query('''
      SELECT
        st.user_id,
        st.class_id,
        st.created_at,
        st.updated_at,
        u.username,
        u.email,
        u.school_id,
        sc.name AS school_name,
        c.name AS class_name
      FROM students st
      JOIN users u ON u.id = st.user_id
      LEFT JOIN schools sc ON sc.id = u.school_id
      LEFT JOIN classes c ON c.id = st.class_id
      WHERE st.user_id = @0
      LIMIT 1
    ''', [userId]);

    if (rows.isEmpty) return null;
    return StudentModel.fromJson(rows.first);
  }

  Future<StudentModel?> upsertStudent({
    required String username,
    required String email,
    required String schoolId,
    required String userId,
    required String classId,
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
      INSERT INTO students (user_id, class_id, created_at, updated_at)
      VALUES (@0, @1, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE
      SET class_id = EXCLUDED.class_id,
          updated_at = NOW()
    ''', [userId, classId]);

    return getStudent(userId);
  }

  Future<bool> deleteStudent(String userId) async {
    final affected = await db.execute('DELETE FROM students WHERE user_id = @0', [userId]);
    return affected > 0;
  }
}
