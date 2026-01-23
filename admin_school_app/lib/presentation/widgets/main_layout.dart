import 'package:admin_school_app/presentation/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/secure_storage_service.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/school/schools_page.dart';
import '../pages/class/classes_page.dart';
import '../pages/teacher/teachers_page.dart';
import '../pages/student/students_page.dart';
import '../pages/admin_user/admin_users_page.dart';
import '../pages/auth/login_page.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentPage;
  final Widget? floatingActionButton;

  const MainLayout({
    super.key,
    required this.child,
    this.currentPage = 'dashboard',
    this.floatingActionButton,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleLogout() async {
    await SecureStorageService.deleteToken();
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0A0E1A),
        drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
        body: Row(
          children: [
            if (!isMobile) SizedBox(width: 280, child: _buildSidebarContent()),
            Expanded(
              child: Column(
                children: [
                  if (isMobile) _buildMobileHeader(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: !isMobile
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              )
                            : null,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: const Color(0xFF0A0E1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1F3A), Color(0xFF0A0E1A)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  widget.currentPage == 'dashboard',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const DashboardPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  Icons.school_rounded,
                  'Școli',
                  [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  widget.currentPage == 'schools',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const SchoolsPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  Icons.class_rounded,
                  'Clase',
                  [const Color(0xFF10B981), const Color(0xFF059669)],
                  widget.currentPage == 'classes',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const ClassesPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  Icons.person_rounded,
                  'Profesori',
                  [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  widget.currentPage == 'teachers',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const TeachersPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  Icons.people_rounded,
                  'Elevi',
                  [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  widget.currentPage == 'students',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const StudentsPage());
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  Icons.manage_accounts_rounded,
                  'Utilizatori',
                  [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                  widget.currentPage == 'users',
                  () {
                    if (MediaQuery.of(context).size.width < 800)
                      Navigator.pop(context);
                    Get.off(() => const AdminUsersPage());
                  },
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.white12,
            height: 32,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.settings,
                  'Setari',
                  [const Color(0xFF4B5563), const Color(0xFF374151)],
                  widget.currentPage == 'settings',
                  () {
                    if (MediaQuery.of(context).size.width < 800) {
                      Navigator.pop(context);
                    }
                    Get.off(() => const SettingsPage());
                  },
                ),
                _buildMenuItem(
                  Icons.logout_rounded,
                  'Deconectare',
                  [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  false,
                  _handleLogout,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Widget _buildMenuItem(
    IconData icon,
    String title,
    List<Color> gradient,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(color: gradient[0].withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        )
                      : null,
                  color: isActive ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
