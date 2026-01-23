import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/teacher_dashboard_controller.dart';
import 'students_catalog.dart';

/// Tab special pentru profesorul diriginte
class HomeroomTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const HomeroomTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchCurrentTeacher(),
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildClassInfo()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildClassStats()),
          SliverToBoxAdapter(child: _buildRecentActivity()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clasa mea',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    final homeroomClass = controller.classes.firstWhereOrNull(
                      (c) => c.id == controller.teacher.value?.classes?.first.id,
                    );
                    return Text(
                      homeroomClass?.name ?? 'Nicio clasă',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Obx(() {
      final homeroomClass = controller.classes.firstWhereOrNull(
        (c) => c.id == controller.teacher.value?.classes?.first.id,
      );

      if (homeroomClass == null) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Nu ești diriginte la nicio clasă',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      final studentCount = homeroomClass.students.length;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1F26), Color(0xFF0F1419)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.people,
                  label: 'Elevi',
                  value: studentCount.toString(),
                  color: Colors.blue,
                ),
                _buildInfoItem(
                  icon: Icons.school,
                  label: 'Anul',
                  value: homeroomClass.name.contains('5') ? '5' :
                         homeroomClass.name.contains('6') ? '6' :
                         homeroomClass.name.contains('7') ? '7' :
                         homeroomClass.name.contains('8') ? '8' : 'N/A',
                  color: Colors.purple,
                ),
                _buildInfoItem(
                  icon: Icons.date_range,
                  label: 'An școlar',
                  value: '2025-2026',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Obx(() {
      final homeroomClass = controller.classes.firstWhereOrNull(
        (c) => c.id == controller.teacher.value?.classes?.first.id,
      );

      if (homeroomClass == null) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acțiuni rapide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.assignment,
                    title: 'Catalog',
                    subtitle: 'Vezi catalogul complet',
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    onTap: () {
                      Get.to(() => StudentsCatalog(
                        schoolClass: homeroomClass,
                        controller: controller,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.analytics,
                    title: 'Rapoarte',
                    subtitle: 'Situație școlară',
                    gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
                    onTap: () => _showReportsDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassStats() {
    return Obx(() {
      final homeroomClass = controller.classes.firstWhereOrNull(
        (c) => c.id == controller.teacher.value?.classes?.first.id,
      );

      if (homeroomClass == null) return const SizedBox();


      final studentIds = homeroomClass.students
          .map((s) => s.userId)
          .whereType<String>()
          .toList();

      final classGrades = controller.grades.where((g) {
        return studentIds.contains(g.studentId);
      }).toList();

      final avgGrade = classGrades.isNotEmpty
          ? (classGrades.map((g) => g.value).reduce((a, b) => a + b) /
              classGrades.length)
          : 0.0;

      final classAttendance = controller.attendanceList.where((a) {
        return studentIds.contains(a.studentId);
      }).toList();

      final presentCount = classAttendance
          .where((a) => a.status.toString().toLowerCase() == 'present')
          .length;
      final totalAttendance = classAttendance.length;
      final attendanceRate = totalAttendance > 0
          ? (presentCount / totalAttendance * 100)
          : 0.0;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistici clasă',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.grade,
                    label: 'Medie generală',
                    value: avgGrade.toStringAsFixed(2),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Prezență',
                    value: '${attendanceRate.toStringAsFixed(0)}%',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Obx(() {
      final homeroomClass = controller.classes.firstWhereOrNull(
        (c) => c.id == controller.teacher.value?.classes?.first.id,
      );

      if (homeroomClass == null) return const SizedBox();

      final studentIds = homeroomClass.students
          .map((s) => s.userId)
          .whereType<String>()
          .toList();


      final recentGrades = controller.grades
          .where((g) => studentIds.contains(g.studentId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final topGrades = recentGrades.take(5).toList();

      if (topGrades.isEmpty) {
        return const SizedBox();
      }

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activitate recentă',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topGrades.map((grade) {
              final student = homeroomClass.students.firstWhereOrNull(
                (s) => s.userId == grade.studentId,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1419),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${grade.value}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.username ?? 'Elev necunoscut',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${grade.subjectName} • ${grade.type.name}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM').format(grade.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  void _showReportsDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: controller.fetchHomeroomClassReport(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Eroare la încărcarea raportului',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Închide'),
                    ),
                  ],
                );
              }

              final data = snapshot.data!;
              final classInfo = data['class_info'] as Map<String, dynamic>;
              final classStats = data['class_statistics'] as Map<String, dynamic>;
              final students = data['students'] as List<dynamic>;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Raport Clasă: ${classInfo['name']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${classInfo['total_students']} elevi',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1419),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Medie',
                          classStats['average_grade'].toString(),
                          Icons.grade,
                          Colors.green,
                        ),
                        _buildStatColumn(
                          'Prezență',
                          '${classStats['attendance_rate']}%',
                          Icons.check_circle,
                          Colors.blue,
                        ),
                        _buildStatColumn(
                          'Note',
                          classStats['total_grades'].toString(),
                          Icons.assignment,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Situație Elevi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final avgGrade = student['average_grade'] as num;
                        final gradeColor = avgGrade >= 8.5
                            ? Colors.green
                            : avgGrade >= 7.0
                                ? Colors.blue
                                : avgGrade >= 5.0
                                    ? Colors.orange
                                    : Colors.red;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1419),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: gradeColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    avgGrade.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: gradeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['username'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Prezență: ${student['attendance_rate']}% • ${student['total_grades']} note',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
