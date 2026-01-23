import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/student.dart';
import '../widgets/buildStatCard.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StudentDataApi? _api;
  StudentModel? _student;
  bool _isLoading = true;
  double _attendancePercentage = 0.0;
  double _gradesAverage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      if (_api == null) {
        final dio = await DioClient.getInstance();
        _api = StudentDataApi(dio);
      }

      final student = await _api!.getMe();
      if (student != null) {
        final attendance = await _api!.getMyAttendance(student.userId ?? '');
        if (attendance.isNotEmpty) {
          final totalDays = attendance.length;
          final presentDays = attendance
              .where((a) => a.status == 'present')
              .length;
          _attendancePercentage = (presentDays / totalDays) * 100;
        }

        final grades = await _api!.getMyGrades();
        if (grades.isNotEmpty) {
          final totalGrades = grades.fold(0, (sum, grade) => sum + grade.value);
          _gradesAverage = totalGrades / grades.length;
        }

        setState(() {
          _student = student;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await SecureStorageService.deleteToken();
    Get.offAll(() => LoginPage());
  }

  String _getInitials() {
    if (_student == null || _student!.username.isEmpty) return '';
    final parts = _student!.username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _student!.username[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: _loadProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F2937), Color(0xFF0B1220)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: () => Get.to(() => SettingsPage()),
                              child: Material(
                                elevation: 6,
                                shape: const CircleBorder(),
                                color: Colors.transparent,
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundColor: const Color(0xFF111827),
                                  child: Text(
                                    _getInitials(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'profile_title'.tr,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _student?.username ?? 'Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _student?.email ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.to(() => SettingsPage()),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: buildStatCard(
                              icon: Icons.check_circle,
                              title: 'attendance'.tr,
                              value:
                                  '${_attendancePercentage.toStringAsFixed(1)}%',
                              color: Colors.greenAccent.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildStatCard(
                              icon: Icons.grade,
                              title: 'grades_short'.tr,
                              value: _gradesAverage > 0
                                  ? _gradesAverage.toStringAsFixed(2)
                                  : 'N/A',
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.snackbar(
                                  'info'.tr,
                                  'change_password'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              icon: const Icon(Icons.lock_open),
                              label: Text('change_password'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F2937),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              label: Text(
                                'logout'.tr,
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
