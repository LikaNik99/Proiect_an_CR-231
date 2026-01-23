import 'package:flutter/material.dart';

import '../../../student/data/model/student.dart';
import '../controllers/teacher_dashboard_controller.dart';

/// Minimal details page for a student, used from the teacher catalog.
///
/// It provides a clean header and the 2 main actions (add grade / add absence).
/// You can extend it later with tabs for grades/attendance/homework.
class StudentDetailsPage extends StatelessWidget {
  final StudentModel student;
  final TeacherDashboardController controller;
  final String classId;
  final String? disciplineName;
  final String teacherName;
  final VoidCallback onAddGrade;
  final VoidCallback onAddAbsence;

  const StudentDetailsPage({
    super.key,
    required this.student,
    required this.controller,
    required this.classId,
    required this.disciplineName,
    required this.teacherName,
    required this.onAddGrade,
    required this.onAddAbsence,
  });

  @override
  Widget build(BuildContext context) {
    final subject = disciplineName ?? 'Nespecificat';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          student.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: Text(
                      student.username.isNotEmpty
                          ? student.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$subject • $teacherName',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddGrade,
                    icon: const Icon(Icons.grade),
                    label: const Text('Adaugă notă'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddAbsence,
                    icon: const Icon(Icons.event_busy),
                    label: const Text('Absență'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Detalii complete (note/absențe/teme) urmează să fie conectate la backend.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
