import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../data/model/teacher_model.dart';

/// Pagină pentru Director - Management Clase
class ClassesManagementPage extends StatefulWidget {
  final TeacherDashboardController controller;

  const ClassesManagementPage({super.key, required this.controller});

  @override
  State<ClassesManagementPage> createState() => _ClassesManagementPageState();
}

class _ClassesManagementPageState extends State<ClassesManagementPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SchoolClass> get _filteredClasses {
    var classes = widget.controller.classes.toList();


    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      classes = classes.where((c) =>
        c.name.toLowerCase().contains(query) ||
        (c.students.any((s) => s.username.toLowerCase().contains(query)))
      ).toList();
    }


    classes.sort((a, b) => a.name.compareTo(b.name));

    return classes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        title: const Text(
          'Management Clase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStats(),
          Expanded(child: _buildClassesList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F26),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1419),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Caută clasă sau elev...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Obx(() {
      final totalClasses = widget.controller.classes.length;
      final totalStudents = widget.controller.classes
          .expand((c) => c.students)
          .toSet()
          .length;


      final avgStudents = totalClasses > 0 ? (totalStudents / totalClasses).toStringAsFixed(1) : '0';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFF1A1F26),
        child: Row(
          children: [
            _buildStatItem('Clase', totalClasses.toString(), Colors.blue),
            _buildStatItem('Total Elevi', totalStudents.toString(), Colors.green),
            _buildStatItem('Mediu/Clasă', avgStudents, Colors.orange),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      final classes = _filteredClasses;

      if (classes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Nicio clasă găsită'
                    : 'Nu există clase',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final schoolClass = classes[index];
          return _buildClassCard(schoolClass);
        },
      );
    });
  }

  Widget _buildClassCard(SchoolClass schoolClass) {

    final homeroomTeacher = schoolClass.teachers.firstWhereOrNull(
      (t) => t.isHomeroom,
    );

    final studentCount = schoolClass.students.length;
    final subjectCount = schoolClass.subjects.length;


    final classGrades = widget.controller.grades
        .where((g) => schoolClass.students.any((s) => s.userId == g.studentId))
        .toList();

    final avgGrade = classGrades.isNotEmpty
        ? classGrades.map((g) => g.value).reduce((a, b) => a + b) / classGrades.length
        : 0.0;

    final gradeColor = avgGrade >= 8.5
        ? Colors.green
        : avgGrade >= 7.0
            ? Colors.blue
            : avgGrade >= 5.0
                ? Colors.orange
                : Colors.red;

    return InkWell(
      onTap: () => _showClassDetails(schoolClass),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolClass.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        homeroomTeacher != null
                            ? 'Diriginte: ${homeroomTeacher.username}'
                            : 'Fără diriginte',
                        style: TextStyle(
                          color: homeroomTeacher != null ? Colors.green : Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (avgGrade > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gradeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      avgGrade.toStringAsFixed(2),
                      style: TextStyle(
                        color: gradeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildInfoChip(Icons.people, '$studentCount elevi', Colors.purple),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.book, '$subjectCount materii', Colors.orange),
                const SizedBox(width: 8),
                if (classGrades.isNotEmpty)
                  _buildInfoChip(Icons.grade, '${classGrades.length} note', Colors.green),
              ],
            ),
            const SizedBox(height: 12),

            if (schoolClass.subjects.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: schoolClass.subjects.take(5).map((subject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showClassDetails(SchoolClass schoolClass) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.class_, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      schoolClass.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        'Diriginte',
                        schoolClass.teachers.firstWhereOrNull((t) => t.isHomeroom)?.username ?? 'Neasignat',
                        Icons.person,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Elevi',
                        '${schoolClass.students.length} elevi',
                        Icons.people,
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),

                      if (schoolClass.students.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1419),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: schoolClass.students.take(10).map((student) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        student.username,
                                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (schoolClass.students.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+ ${schoolClass.students.length - 10} mai mulți',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Materii',
                        '${schoolClass.subjects.length} materii',
                        Icons.book,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),

                      if (schoolClass.subjects.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: schoolClass.subjects.map((subject) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                subject.name,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();

                        widget.controller.currentIndex.value = 1;
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Vezi Catalog'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildDetailSection(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
