import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/dashboard/dashboard_controller.dart';
import '../../widgets/main_layout.dart';
import '../school/schools_page.dart';
import '../class/classes_page.dart';
import '../teacher/teachers_page.dart';
import '../student/students_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SafeArea(
      child: MainLayout(
        currentPage: 'dashboard',
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }
          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reîncearcă'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  ),
                ],
              ),
            );
          }

          final stats = controller.stats.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (stats != null) _buildStatCards(stats, isMobile),
                const SizedBox(height: 24),
                _buildQuickActions(isMobile),
              ],
            ),
          );
        }),
      ),
    );
  }


  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM yyyy', 'ro_RO').format(DateTime.now()),
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.admin_panel_settings, color: Colors.white),
        ),
      ],
    );
  }


  Widget _buildStatCards(dynamic stats, bool isMobile) {
    final cards = [
      _kpiCard('Școli', stats.totalSchools, Icons.school, const Color(0xFF3B82F6)),
      _kpiCard('Clase', stats.totalClasses, Icons.class_, const Color(0xFF10B981)),
      _kpiCard('Elevi', stats.totalStudents, Icons.people, const Color(0xFF8B5CF6)),
      _kpiCard('Profesori', stats.totalTeachers, Icons.person, const Color(0xFFF59E0B)),
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _kpiCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActions(bool isMobile) {
    final actions = [
      _quickAction('Școli', Icons.school, const Color(0xFF3B82F6), const SchoolsPage()),
      _quickAction('Clase', Icons.class_, const Color(0xFF10B981), const ClassesPage()),
      _quickAction('Profesori', Icons.person, const Color(0xFFF59E0B), const TeachersPage()),
      _quickAction('Elevi', Icons.people, const Color(0xFF8B5CF6), const StudentsPage()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acțiuni rapide',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: actions,
        ),
      ],
    );
  }

  Widget _quickAction(String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Get.to(() => page),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
