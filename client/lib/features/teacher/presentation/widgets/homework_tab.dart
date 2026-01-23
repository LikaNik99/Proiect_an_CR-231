import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/homework_entity.dart';

class HomeworkTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const HomeworkTab({super.key, required this.controller});

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
                const Icon(Icons.home_work, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Teme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _showAddHomeworkDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHomework.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                );
              }

              if (controller.homeworkList.isEmpty) {
                return const Center(
                  child: Text(
                    'Nu există teme create',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.homeworkList.length,
                itemBuilder: (context, index) {
                  final homework = controller.homeworkList[index];
                  return _buildHomeworkCard(homework);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    return Card(
      color: const Color(0xFF1D1E33),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(homework.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(homework.status),
                    style: TextStyle(
                      color: _getStatusColor(homework.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (homework.description != null) ...[
              const SizedBox(height: 8),
              Text(
                homework.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Termen: ${_formatDate(homework.dueDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.completed:
        return Colors.green;
      case HomeworkStatus.pending:
        return Colors.orange;
      case HomeworkStatus.overdue:
        return Colors.red;
    }
  }

  String _getStatusText(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.completed:
        return 'Completată';
      case HomeworkStatus.pending:
        return 'În așteptare';
      case HomeworkStatus.overdue:
        return 'Expirată';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddHomeworkDialog(BuildContext context) {
    Get.snackbar(
      'În dezvoltare',
      'Funcția de creare teme va fi implementată curând',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
