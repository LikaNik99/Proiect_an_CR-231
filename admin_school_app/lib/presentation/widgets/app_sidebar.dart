import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/school/schools_page.dart';
import '../pages/class/classes_page.dart';
import '../pages/teacher/teachers_page.dart';
import '../pages/student/students_page.dart';
import '../pages/admin_user/admin_users_page.dart';
import '../pages/settings/settings_page.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                  Color(0xFFEC4899),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistem de management școlar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const DashboardPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.school_rounded,
                  title: 'Școli',
                  gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const SchoolsPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.class_rounded,
                  title: 'Clase',
                  gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const ClassesPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.person_rounded,
                  title: 'Profesori',
                  gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const TeachersPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  title: 'Elevi',
                  gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const StudentsPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Utilizatori',
                  gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const AdminUsersPage());
                  },
                ),
                const Divider(
                  color: Colors.white24,
                  height: 32,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  title: 'Setări',
                  gradient: [const Color(0xFF64748B), const Color(0xFF475569)],
                  onTap: () {
                    Get.back();
                    Get.to(() => const SettingsPage());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}