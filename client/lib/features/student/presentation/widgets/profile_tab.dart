import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_dashboard_controller.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../pages/attendance_page.dart';
import '../pages/settings_page.dart';
import '../../data/datasource/student_data_api.dart';

class ProfileTab extends StatelessWidget {
  final StudentDashboardController controller;

  const ProfileTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => controller.fetchStudentData(forceRefresh: true),
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
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final student = controller.student.value;
      if (student == null) return const SizedBox(height: 100);

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
                  child: Text(
                    student.username.isNotEmpty
                        ? student.username[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.username,
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
                      student.email,
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
                          Text(
                            'student_role'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
    return Obx(() {
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
                Text(
                  'profile_stats_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.school_rounded,
                    label: 'overall_average'.tr,
                    value: controller.averageGrade.toStringAsFixed(2),
                    color: const Color(0xFFA855F7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle_rounded,
                    label: 'attendance'.tr,
                    value: '${controller.attendancePercentage.toStringAsFixed(0)}%',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.assignment_rounded,
                    label: 'pending_homework'.tr,
                    value: '${controller.pendingHomeworkCount}',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'total_grades'.tr,
                    value: '${controller.grades.length}',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            icon: Icons.calendar_month,
            title: 'attendance_detail'.tr,
            subtitle: 'attendance_detail_sub'.tr,
            onTap: () => Get.to(() => const AttendancePage()),
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'change_password'.tr,
            subtitle: 'change_password_sub'.tr,
            onTap: () => _showChangePasswordDialog(),
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'settings_title'.tr,
            subtitle: 'settings_sub'.tr,
            onTap: () => Get.to(() => const SettingsPage()),
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'about_app'.tr,
            subtitle: 'about_app_sub'.tr,
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
    Widget? trailing,
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
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 22),
              const SizedBox(width: 12),
              Text(
                'logout'.tr,
                style: const TextStyle(
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final RxBool isLoading = false.obs;
    final RxString errorMessage = ''.obs;
    final RxBool showCurrentPassword = false.obs;
    final RxBool showNewPassword = false.obs;
    final RxBool showConfirmPassword = false.obs;

    Get.dialog(
      Obx(() => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'change_password'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildPasswordFieldWithVisibility(
                controller: currentPasswordController,
                label: 'current_password'.tr,
                showPassword: showCurrentPassword,
              ),
              const SizedBox(height: 16),
              _buildPasswordFieldWithVisibility(
                controller: newPasswordController,
                label: 'new_password'.tr,
                showPassword: showNewPassword,
              ),
              const SizedBox(height: 16),
              _buildPasswordFieldWithVisibility(
                controller: confirmPasswordController,
                label: 'confirm_password'.tr,
                showPassword: showConfirmPassword,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading.value ? null : () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: isLoading.value ? null : () async {
              errorMessage.value = '';


              if (currentPasswordController.text.isEmpty) {
                errorMessage.value = 'enter_current_password'.tr;
                return;
              }
              if (newPasswordController.text.isEmpty) {
                errorMessage.value = 'enter_new_password'.tr;
                return;
              }
              if (newPasswordController.text.length < 6) {
                errorMessage.value = 'new_password_min_length'.tr;
                return;
              }
              if (newPasswordController.text != confirmPasswordController.text) {
                errorMessage.value = 'passwords_do_not_match'.tr;
                return;
              }
              if (currentPasswordController.text == newPasswordController.text) {
                errorMessage.value = 'new_password_different_from_current'.tr;
                return;
              }

              isLoading.value = true;

              try {
                final dio = await DioClient.getInstance();
                final api = StudentDataApi(dio);

                final result = await api.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                isLoading.value = false;

                if (result['success'] == true) {
                  Get.back();
                  Get.snackbar(
                    'success'.tr,
                    result['message'] ?? 'password_changed_successfully'.tr,
                    backgroundColor: const Color(0xFF10B981),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 3),
                  );
                } else {
                  errorMessage.value = result['message'] ?? 'error_changing_password'.tr;
                }
              } catch (e) {
                isLoading.value = false;
                errorMessage.value = 'error_changing_password_check_connection'.tr;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('save'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Widget _buildPasswordFieldWithVisibility({
    required TextEditingController controller,
    required String label,
    required RxBool showPassword,
  }) {
    return Obx(() => TextField(
      controller: controller,
      obscureText: !showPassword.value,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF252B35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword.value ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () => showPassword.value = !showPassword.value,
        ),
      ),
    ));
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
              'A modern application for managing school activities.',
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
                  const Icon(Icons.code, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Made with Flutter',
                    style: TextStyle(color: Colors.grey[400]),
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
        title: Text(
          'logout'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'logout_confirmation'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await SecureStorageService.deleteToken();
              Get.offAll(() => LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('logout'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
