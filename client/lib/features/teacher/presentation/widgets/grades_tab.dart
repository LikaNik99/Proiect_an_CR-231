import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/grade_entity.dart';

class GradesTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const GradesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1D1E33),
            child: Row(
              children: [
                const Icon(Icons.grade, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showAddGradeDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingGrades.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              if (controller.grades.isEmpty) {
                return const Center(
                  child: Text(
                    'Nu există note adăugate',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.grades.length,
                itemBuilder: (context, index) {
                  final grade = controller.grades[index];
                  return _buildGradeCard(grade);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(Grade grade) {
    return Card(
      color: const Color(0xFF1D1E33),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getGradeColor(grade.value).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  grade.value.toString(),
                  style: TextStyle(
                    color: _getGradeColor(grade.value),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                    grade.subjectName ?? 'Materie necunoscută',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getGradeTypeText(grade.type),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    _formatDate(grade.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(int value) {
    if (value >= 9) return Colors.green;
    if (value >= 7) return Colors.blue;
    if (value >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getGradeTypeText(GradeType type) {
    switch (type) {
      case GradeType.exam:
        return 'Examen';
      case GradeType.test:
        return 'Test';
      case GradeType.homework:
        return 'Temă';
      case GradeType.assignment:
        return 'Lucrare';
      case GradeType.other:
        return 'Altele';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddGradeDialog(BuildContext context) {
    Get.snackbar(
      'În dezvoltare',
      'Funcția de adăugare note va fi implementată curând',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
