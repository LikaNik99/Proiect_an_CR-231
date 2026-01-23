import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/grade_entity.dart';
class GradesCatalogPage extends StatelessWidget {
  final TeacherDashboardController controller;
  const GradesCatalogPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Catalog Note',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => controller.fetchTeacherGrades(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingGrades.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        final grades = controller.grades;
        if (grades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text('Nu ai pus inca nicio nota', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        final groupedGrades = <String, List<Grade>>{};
        for (var grade in grades) {
          final studentName = controller.allStudents.firstWhereOrNull((s) => s.userId == grade.studentId)?.username ?? 'Student necunoscut';
          groupedGrades.putIfAbsent(studentName, () => []).add(grade);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(grades),
            const SizedBox(height: 16),
            ...groupedGrades.entries.map((entry) => _buildStudentGradeCard(entry.key, entry.value)).toList(),
          ],
        );
      }),
    );
  }
  Widget _buildSummaryCard(List<Grade> grades) {
    final totalGrades = grades.length;
    final avgGrade = grades.isEmpty ? 0.0 : grades.map((g) => g.value).reduce((a, b) => a + b) / totalGrades;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Note', totalGrades.toString(), Icons.grade),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildStatItem('Media', avgGrade.toStringAsFixed(2), Icons.trending_up),
        ],
      ),
    );
  }
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
  Widget _buildStudentGradeCard(String studentName, List<Grade> grades) {
    grades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final avg = grades.map((g) => g.value).reduce((a, b) => a + b) / grades.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: Text(studentName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent)),
        ),
        title: Text(studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text('${grades.length} ${grades.length == 1 ? 'nota' : 'note'}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getGradeColor(avg).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('M: ${avg.toStringAsFixed(2)}', style: TextStyle(color: _getGradeColor(avg), fontWeight: FontWeight.bold)),
        ),
        children: grades.map((grade) => _buildGradeItem(grade)).toList(),
      ),
    );
  }
  Widget _buildGradeItem(Grade grade) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F1419), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: _getGradeColor(grade.value.toDouble()).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(grade.value.toString(), style: TextStyle(color: _getGradeColor(grade.value.toDouble()), fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.subjectName ?? 'Nespecificat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_getGradeTypeLabel(grade.type), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 4),
                Text(dateFormat.format(grade.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Color _getGradeColor(double grade) {
    if (grade >= 9) return Colors.green;
    if (grade >= 7) return Colors.blue;
    if (grade >= 5) return Colors.orange;
    return Colors.red;
  }
  String _getGradeTypeLabel(GradeType type) {
    switch (type) {
      case GradeType.exam: return 'Examen';
      case GradeType.test: return 'Test';
      case GradeType.homework: return 'Tema';
      case GradeType.assignment: return 'Lucrare';
      case GradeType.other: return 'Altele';
    }
  }
}
