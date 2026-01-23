import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/teacher/teachers_controller.dart';
import '../../widgets/main_layout.dart';
import 'teacher_form_page.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeachersController());
    final isMobile = MediaQuery.of(context).size.width < 800;

    return MainLayout(
      currentPage: 'teachers',
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const TeacherFormPage()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Adaugă Profesor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (controller.errorMessage.isNotEmpty) {
                return _buildError(controller);
              }

              if (controller.teachers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.loadTeachers,
                backgroundColor: const Color(0xFF1A1F3A),
                color: const Color(0xFFF59E0B),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isMobile
                      ? ListView.builder(
                          itemCount: controller.teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = controller.teachers[index];
                            return _buildMobileCard(controller, teacher);
                          },
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildDataTable(controller),
                            ),
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profesori',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Gestionare cadre didactice',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(TeachersController controller, teacher) {
    final username = teacher.user?.username ?? '-';
    final schoolName = teacher.schoolName ?? controller.schoolNameFor(teacher.schoolId);
    final subject = (teacher.subject ?? '').trim().isEmpty ? '-' : (teacher.subject ?? '-');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF1A1F3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Școală: $schoolName',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text('Specializări: $subject',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => TeacherFormPage(teacherId: teacher.userId)),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editează'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(controller, teacher.userId),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Șterge'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(TeachersController controller) {
    return DataTable(
      headingRowColor:
      MaterialStateProperty.all(const Color(0xFFF59E0B).withOpacity(0.15)),
      headingRowHeight: 60,
      dataRowHeight: 65,
      headingTextStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      dataTextStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
      columns: const [
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Școală')),
        DataColumn(label: Text('Specializări')),
        DataColumn(label: Text('Acțiuni')),
      ],
      rows: controller.teachers.map((teacher) {
        final username = teacher.user?.username ?? '-';
        final schoolName = teacher.schoolName ?? controller.schoolNameFor(teacher.schoolId);
        final subject = (teacher.subject ?? '').trim().isEmpty ? '-' : (teacher.subject ?? '-');

        return DataRow(cells: [
          DataCell(Text(username)),
          DataCell(Text(schoolName)),
          DataCell(Text(subject)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Get.to(() => TeacherFormPage(teacherId: teacher.userId)),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(controller, teacher.userId),
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.person_outline, size: 64, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 24),
          const Text('Nu există profesori',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Apasă butonul + pentru a adăuga primul profesor',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError(TeachersController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.loadTeachers,
            icon: const Icon(Icons.refresh),
            label: const Text('Reîncearcă'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(TeachersController controller, String teacherUserId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirmare Ștergere',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Sigur doriți să ștergeți acest profesor?\nAceastă acțiune nu poate fi anulată.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Anulează', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteTeacher(teacherUserId);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Șterge', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
