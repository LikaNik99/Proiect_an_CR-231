import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../pages/settings_page.dart';
import '../pages/change_password_page.dart';

class ProfileTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const ProfileTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchCurrentTeacher(),
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsSection(),
            _buildMenuSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final teacher = controller.teacher.value;
      if (teacher == null) return const SizedBox(height: 200);

      final avatarUrl = teacher.avatarUrl;
      final imageProvider = avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(
              avatarUrl.startsWith('/') ? '${AppConfig.baseUrl}$avatarUrl' : avatarUrl,
            )
          : null;

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [

              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    await controller.uploadAvatar(picked.path);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: imageProvider as ImageProvider<Object>?,
                        child: imageProvider == null
                            ? Text(
                                teacher.username[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF667eea),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.blue],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              teacher.subject ?? 'Profesor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2530), Color(0xFF1A1F26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Statistici',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.class_rounded,
                  label: 'Clase',
                  value: '${controller.totalClasses}',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_rounded,
                  label: 'Elevi',
                  value: '${controller.totalStudents}',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          )),
          const SizedBox(height: 14),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.grade_rounded,
                  label: 'Note date',
                  value: '${controller.totalGrades}',
                  color: const Color(0xFFA855F7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule_rounded,
                  label: 'Ore azi',
                  value: '${controller.lessonsToday}',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A303C),
            const Color(0xFF252B35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Schimbă parola',
            subtitle: 'Actualizează-ți parola de acces',
            onTap: () => Get.to(() => const ChangePasswordPage()),
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Setări',
            subtitle: 'Limbă, notificări, preferințe',
            onTap: () => Get.to(() => SettingsPage(controller: controller)),
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Despre aplicație',
            subtitle: 'Versiune și informații',
            onTap: () => _showAboutDialog(),
          ),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2530), Color(0xFF1A1F26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.2),
                        Colors.blueAccent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.blueAccent, size: 24),
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
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showLogoutConfirmation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.red.withOpacity(0.4), width: 2),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 22),
              SizedBox(width: 12),
              Text(
                'Deconectare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blueAccent, size: 28),
            SizedBox(width: 12),
            Text(
              'School App',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            const Text(
              'O aplicație modernă pentru gestionarea activităților școlare.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dezvoltat cu Flutter',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Deconectare',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ești sigur că vrei să te deconectezi?',
          style: TextStyle(color: Colors.white70),
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
              await SecureStorageService.clearAll();
              DioClient.reset();
              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Deconectare',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
