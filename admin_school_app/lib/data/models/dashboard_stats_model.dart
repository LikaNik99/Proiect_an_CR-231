import '../../domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  DashboardStatsModel({
    required super.totalSchools,
    required super.totalClasses,
    required super.totalStudents,
    required super.totalTeachers,
    required super.usersByRole,
    required super.schoolsStatus,
    required super.recentUsers30Days,
    required super.classDistribution,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalSchools: json['total_schools'] as int? ?? 0,
      totalClasses: json['total_classes'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      totalTeachers: json['total_teachers'] as int? ?? 0,
      usersByRole: Map<String, int>.from(json['users_by_role'] as Map? ?? {}),
      schoolsStatus: SchoolsStatusModel.fromJson(
        json['schools_status'] as Map<String, dynamic>? ?? {},
      ),
      recentUsers30Days: json['recent_users_30_days'] as int? ?? 0,
      classDistribution: (json['class_distribution'] as List? ?? [])
          .map((e) => ClassDistributionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SchoolsStatusModel extends SchoolsStatus {
  SchoolsStatusModel({
    required super.active,
    required super.inactive,
  });

  factory SchoolsStatusModel.fromJson(Map<String, dynamic> json) {
    return SchoolsStatusModel(
      active: json['active'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
    );
  }
}

class ClassDistributionModel extends ClassDistribution {
  ClassDistributionModel({
    required super.className,
    required super.studentCount,
  });

  factory ClassDistributionModel.fromJson(Map<String, dynamic> json) {
    return ClassDistributionModel(
      className: json['class_name'] as String? ?? '',
      studentCount: json['student_count'] as int? ?? 0,
    );
  }
}