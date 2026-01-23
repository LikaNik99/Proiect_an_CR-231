import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';

class HomeTabSimple extends StatelessWidget {
  final TeacherDashboardController controller;

  const HomeTabSimple({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Obx(() {
              final teacher = controller.teacher.value;
              if (teacher == null) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bună, ${teacher.username}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher.subject ?? 'Profesor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 32),


            Obx(() => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Clase',
                    controller.totalClasses.toString(),
                    Icons.class_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Elevi',
                    controller.totalStudents.toString(),
                    Icons.people_outline,
                    Colors.green,
                  ),
                ),
              ],
            )),

            const SizedBox(height: 16),

            Obx(() => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Note (7 zile)',
                    controller.gradesThisWeek.toString(),
                    Icons.grade_outlined,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Absențe azi',
                    controller.absencesToday.toString(),
                    Icons.warning_amber_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            )),

            const SizedBox(height: 32),


            const Text(
              'Acțiuni rapide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              'Vezi toate clasele',
              'Accesează lista cu toate clasele tale',
              Icons.class_outlined,
              Colors.blue,
              () => controller.currentIndex.value = 1,
            ),

            const SizedBox(height: 12),

            _buildActionCard(
              'Adaugă notă',
              'Adaugă o notă nouă pentru elevi',
              Icons.add_circle_outline,
              Colors.green,
              () {
                controller.currentIndex.value = 1;
                Get.snackbar(
                  'Info',
                  'Mergi la tab Activități → Note pentru a adăuga',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),

            const SizedBox(height: 12),

            _buildActionCard(
              'Crează temă',
              'Creează o temă nouă pentru clasă',
              Icons.home_work_outlined,
              Colors.purple,
              () {
                controller.currentIndex.value = 1;
                Get.snackbar(
                  'Info',
                  'Mergi la tab Activități → Teme pentru a crea',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
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
}
