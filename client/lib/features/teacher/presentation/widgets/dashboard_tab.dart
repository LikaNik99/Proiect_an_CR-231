import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';

class DashboardTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const DashboardTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Obx(() => _buildWelcomeCard()),
            const SizedBox(height: 24),


            const Text(
              'Statistici',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => _buildStatsGrid()),
            const SizedBox(height: 24),


            const Text(
              'Acțiuni rapide',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final teacher = controller.teacher.value;
    if (teacher == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              teacher.username[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2193b0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bun venit,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  teacher.username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  teacher.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Clase',
          controller.totalClasses.toString(),
          Icons.class_,
          const Color(0xFF6C63FF),
        ),
        _buildStatCard(
          'Elevi',
          controller.totalStudents.toString(),
          Icons.people,
          const Color(0xFFFF6584),
        ),
        _buildStatCard(
          'Note săptămâna asta',
          controller.gradesThisWeek.toString(),
          Icons.grade,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Absențe azi',
          controller.absencesToday.toString(),
          Icons.warning_amber,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildQuickActionButton(
          'Adaugă notă',
          Icons.add_circle,
          const Color(0xFF4CAF50),
          () => controller.currentIndex.value = 2,
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          'Crează temă',
          Icons.home_work,
          const Color(0xFF2196F3),
          () => controller.currentIndex.value = 3,
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          'Marchează prezența',
          Icons.check_circle,
          const Color(0xFFFF9800),
          () => controller.currentIndex.value = 5,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
