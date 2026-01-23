import '../../../core/database/database_connection_manager.dart';
import '../../models/dashboard_stats_model.dart';

/// Direct DB datasource for dashboard stats (PostgreSQL)
class DashboardDbDataSource {
  final DatabaseConnectionManager db;

  DashboardDbDataSource(this.db);

  Future<DashboardStatsModel> getDashboardStats() async {

    final totalSchools = await _count('schools');
    final totalClasses = await _count('classes');
    final totalStudents = await _count('students');
    final totalTeachers = await _count('teachers');


    final roleRows = await db.query('''
      SELECT role, COUNT(*)::int AS cnt
      FROM users
      GROUP BY role
    ''');

    final usersByRole = <String, int>{};
    for (final r in roleRows) {
      usersByRole[(r['role'] ?? '').toString()] =
          (r['cnt'] as int?) ?? int.tryParse(r['cnt']?.toString() ?? '0') ?? 0;
    }


    int active = 0;
    int inactive = 0;
    try {
      final statusRows = await db.query('''
        SELECT is_active, COUNT(*)::int AS cnt
        FROM schools
        GROUP BY is_active
      ''');
      for (final r in statusRows) {
        final isActive = (r['is_active'] == true) ||
            (r['is_active']?.toString() == 'true');
        final cnt = (r['cnt'] as int?) ??
            int.tryParse(r['cnt']?.toString() ?? '0') ??
            0;
        if (isActive) {
          active += cnt;
        } else {
          inactive += cnt;
        }
      }
    } catch (_) {
      active = totalSchools;
      inactive = 0;
    }


    int recentUsers30Days = 0;
    try {
      final rows = await db.query('''
        SELECT COUNT(*)::int AS cnt
        FROM users
        WHERE created_at >= NOW() - INTERVAL '30 days'
      ''');
      if (rows.isNotEmpty) {
        final v = rows.first['cnt'];
        recentUsers30Days =
            (v as int?) ?? int.tryParse(v?.toString() ?? '0') ?? 0;
      }
    } catch (_) {
      recentUsers30Days = 0;
    }


    final classDistribution = <ClassDistributionModel>[];
    try {
      final rows = await db.query('''
        SELECT c.name AS class_name, COUNT(s.user_id)::int AS student_count
        FROM classes c
        LEFT JOIN students s ON s.class_id = c.id
        GROUP BY c.name
        ORDER BY student_count DESC
        LIMIT 10
      ''');

      for (final r in rows) {
        classDistribution.add(
          ClassDistributionModel(
            className: (r['class_name'] ?? '').toString(),
            studentCount: (r['student_count'] as int?) ??
                int.tryParse(r['student_count']?.toString() ?? '0') ??
                0,
          ),
        );
      }
    } catch (_) {

    }

    return DashboardStatsModel(
      totalSchools: totalSchools,
      totalClasses: totalClasses,
      totalStudents: totalStudents,
      totalTeachers: totalTeachers,
      usersByRole: usersByRole,
      schoolsStatus: SchoolsStatusModel(active: active, inactive: inactive),
      recentUsers30Days: recentUsers30Days,
      classDistribution: classDistribution,
    );
  }

  Future<int> _count(String table) async {
    final rows = await db.query('SELECT COUNT(*)::int AS cnt FROM $table');
    final v = rows.first['cnt'];
    return (v as int?) ?? int.tryParse(v?.toString() ?? '0') ?? 0;
  }
}
