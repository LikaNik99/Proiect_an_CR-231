class DashboardStatsEntity {
  final int totalSchools;
  final int totalClasses;
  final int totalStudents;
  final int totalTeachers;
  final Map<String, int> usersByRole;
  final SchoolsStatus schoolsStatus;
  final int recentUsers30Days;
  final List<ClassDistribution> classDistribution;

  DashboardStatsEntity({
    required this.totalSchools,
    required this.totalClasses,
    required this.totalStudents,
    required this.totalTeachers,
    required this.usersByRole,
    required this.schoolsStatus,
    required this.recentUsers30Days,
    required this.classDistribution,
  });
}

class SchoolsStatus {
  final int active;
  final int inactive;

  SchoolsStatus({
    required this.active,
    required this.inactive,
  });
}

class ClassDistribution {
  final String className;
  final int studentCount;

  ClassDistribution({
    required this.className,
    required this.studentCount,
  });
}