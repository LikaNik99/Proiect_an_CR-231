import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../pages/teachers_management_page.dart';
import '../pages/classes_management_page.dart';
import '../pages/reports_page.dart';

/// Dashboard special pentru Director
class DirectorDashboard extends StatelessWidget {
  final TeacherDashboardController controller;

  const DirectorDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchCurrentTeacher(),
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildOverviewStats()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildSchoolStats()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Director',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final teacher = controller.teacher.value;
                        return Text(
                          teacher?.username ?? 'Director',
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
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistici generale',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {

            final totalClasses = controller.classes.length;

            final allStudents = controller.classes
                .expand((c) => c.students)
                .toSet()
                .length;

            final totalGrades = controller.grades.length;

            final avgGrade = totalGrades > 0
                ? controller.grades
                        .map((g) => g.value)
                        .reduce((a, b) => a + b) /
                    totalGrades
                : 0.0;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  icon: Icons.class_,
                  label: 'Clase',
                  value: totalClasses.toString(),
                  color: Colors.blue,
                  gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                _buildStatCard(
                  icon: Icons.people,
                  label: 'Elevi',
                  value: allStudents.toString(),
                  color: Colors.purple,
                  gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
                ),
                _buildStatCard(
                  icon: Icons.grade,
                  label: 'Medie generală',
                  value: avgGrade.toStringAsFixed(2),
                  color: Colors.green,
                  gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
                _buildStatCard(
                  icon: Icons.assignment,
                  label: 'Note trimise',
                  value: totalGrades.toString(),
                  color: Colors.orange,
                  gradient: const [Color(0xFFFA709A), Color(0xFFFEE140)],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.people,
            title: 'Profesori',
            subtitle: 'Gestionează profesorii',
            color: Colors.orange,
            onTap: () async {
              await controller.fetchAllTeachers();
              Get.to(() => TeachersManagementPage(controller: controller));
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.class_,
            title: 'Clase',
            subtitle: 'Vezi și administrează clase',
            color: Colors.blue,
            onTap: () {
              Get.to(() => ClassesManagementPage(controller: controller));
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.analytics,
            title: 'Rapoarte',
            subtitle: 'Rapoarte complete și statistici',
            color: Colors.green,
            onTap: () {
              Get.to(() => ReportsPage(controller: controller));
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.notifications,
            title: 'Anunțuri',
            subtitle: 'Trimite anunțuri către toți',
            color: Colors.purple,
            onTap: () => _showAnnouncementDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolStats() {
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
            'Performanță pe clase',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.classes.isEmpty) {
              return Center(
                child: Text(
                  'Nu există clase înregistrate',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              );
            }

            return Column(
              children: controller.classes.take(5).map((schoolClass) {
                final studentIds = schoolClass.students
                    .map((s) => s.userId)
                    .whereType<String>()
                    .toList();

                final classGrades = controller.grades
                    .where((g) => studentIds.contains(g.studentId))
                    .toList();

                final avgGrade = classGrades.isNotEmpty
                    ? classGrades
                            .map((g) => g.value)
                            .reduce((a, b) => a + b) /
                        classGrades.length
                    : 0.0;

                final gradeColor = avgGrade >= 8.5
                    ? Colors.green
                    : avgGrade >= 7.0
                        ? Colors.blue
                        : avgGrade >= 5.0
                            ? Colors.orange
                            : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gradeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.class_, color: gradeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schoolClass.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${schoolClass.students.length} elevi',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: gradeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          avgGrade > 0
                              ? avgGrade.toStringAsFixed(2)
                              : 'N/A',
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedTarget = 'ALL';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Anunț nou',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Titlu anunț',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Mesajul anunțului...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.message, color: Colors.grey),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trimite către:',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTarget = 'ALL'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'ALL'
                                      ? Colors.purple.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedTarget == 'ALL'
                                        ? Colors.purple
                                        : Colors.grey[700]!,
                                  ),
                                ),
                                child: Text(
                                  'Toți',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTarget == 'ALL'
                                        ? Colors.purple
                                        : Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTarget = 'TEACHER'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'TEACHER'
                                      ? Colors.purple.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedTarget == 'TEACHER'
                                        ? Colors.purple
                                        : Colors.grey[700]!,
                                  ),
                                ),
                                child: Text(
                                  'Profesori',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTarget == 'TEACHER'
                                        ? Colors.purple
                                        : Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTarget = 'STUDENT'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'STUDENT'
                                      ? Colors.purple.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedTarget == 'STUDENT'
                                        ? Colors.purple
                                        : Colors.grey[700]!,
                                  ),
                                ),
                                child: Text(
                                  'Elevi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTarget == 'STUDENT'
                                        ? Colors.purple
                                        : Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Anulează',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Eroare',
                    'Completează toate câmpurile',
                    backgroundColor: Colors.red.withOpacity(0.2),
                    colorText: Colors.white,
                  );
                  return;
                }


                try {
                  await controller.broadcastAnnouncement(
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    targetRoles: selectedTarget == 'ALL'
                        ? null
                        : [selectedTarget],
                  );

                  Get.back();
                  Get.snackbar(
                    'Succes',
                    'Anunțul a fost trimis cu succes',
                    backgroundColor: Colors.green.withOpacity(0.2),
                    colorText: Colors.white,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  );
                } catch (e) {
                  Get.snackbar(
                    'Eroare',
                    'Nu s-a putut trimite anunțul: $e',
                    backgroundColor: Colors.red.withOpacity(0.2),
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Trimite',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
