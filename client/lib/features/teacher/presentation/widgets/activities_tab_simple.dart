import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/grade_entity.dart';
import '../../domain/entities/homework_entity.dart';

class ActivitiesTabSimple extends StatefulWidget {
  final TeacherDashboardController controller;

  const ActivitiesTabSimple({super.key, required this.controller});

  @override
  State<ActivitiesTabSimple> createState() => _ActivitiesTabSimpleState();
}

class _ActivitiesTabSimpleState extends State<ActivitiesTabSimple>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1A1F26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activități',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blueAccent,
                  indicatorWeight: 3,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Clase'),
                    Tab(text: 'Note'),
                    Tab(text: 'Teme'),
                  ],
                ),
              ],
            ),
          ),


          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClassesTab(),
                _buildGradesTab(),
                _buildHomeworkTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildClassesTab() {
    return Obx(() {
      if (widget.controller.classes.isEmpty) {
        return _buildEmptyState(
          'Nu ai clase asignate',
          Icons.class_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.controller.classes.length,
        itemBuilder: (context, index) {
          final schoolClass = widget.controller.classes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      schoolClass.name[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                        schoolClass.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${schoolClass.students.length} elevi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
              ],
            ),
          );
        },
      );
    });
  }


  Widget _buildGradesTab() {
    return Obx(() {
      if (widget.controller.isLoadingGrades.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      if (widget.controller.grades.isEmpty) {
        return _buildEmptyState(
          'Nu ai adăugat note încă',
          Icons.grade_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.controller.grades.length,
        itemBuilder: (context, index) {
          final grade = widget.controller.grades[index];
          return _buildGradeCard(grade);
        },
      );
    });
  }

  Widget _buildGradeCard(Grade grade) {
    final gradeColor = _getGradeColor(grade.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                grade.value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
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
                  grade.subjectName ?? 'Materie',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getGradeTypeText(grade.type)} • ${_formatDate(grade.createdAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHomeworkTab() {
    return Obx(() {
      if (widget.controller.isLoadingHomework.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      if (widget.controller.homeworkList.isEmpty) {
        return _buildEmptyState(
          'Nu ai creat teme încă',
          Icons.home_work_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.controller.homeworkList.length,
        itemBuilder: (context, index) {
          final homework = widget.controller.homeworkList[index];
          return _buildHomeworkCard(homework);
        },
      );
    });
  }

  Widget _buildHomeworkCard(Homework homework) {
    final statusColor = _getStatusColor(homework.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  homework.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(homework.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (homework.description != null) ...[
            const SizedBox(height: 8),
            Text(
              homework.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Termen: ${_formatDate(homework.dueDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
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
      case GradeType.exam: return 'Examen';
      case GradeType.test: return 'Test';
      case GradeType.homework: return 'Temă';
      case GradeType.assignment: return 'Lucrare';
      case GradeType.other: return 'Altele';
    }
  }

  Color _getStatusColor(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.completed: return Colors.green;
      case HomeworkStatus.pending: return Colors.orange;
      case HomeworkStatus.overdue: return Colors.red;
    }
  }

  String _getStatusText(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.completed: return 'Completată';
      case HomeworkStatus.pending: return 'Pending';
      case HomeworkStatus.overdue: return 'Expirată';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
