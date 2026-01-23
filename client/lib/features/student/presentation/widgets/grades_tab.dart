import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/student_dashboard_controller.dart';
import '../../data/model/grade_model.dart';

class GradesTab extends StatefulWidget {
  final StudentDashboardController controller;

  const GradesTab({super.key, required this.controller});

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  String? _selectedSubject;
  String _sortBy = 'date';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => widget.controller.fetchGrades(forceRefresh: true),
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildOverallStats()),
          SliverToBoxAdapter(child: _buildSubjectFilter()),
          SliverToBoxAdapter(child: _buildGradesList()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Text(
              'grades_title'.tr,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.grey),
              color: const Color(0xFF1A1F26),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: _sortBy == 'date' ? Colors.blueAccent : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'sort_by_date'.tr,
                        style: TextStyle(
                          color: _sortBy == 'date' ? Colors.blueAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'value',
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color: _sortBy == 'value' ? Colors.blueAccent : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'sort_by_value'.tr,
                        style: TextStyle(
                          color: _sortBy == 'value' ? Colors.blueAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    return Obx(() {
      final average = widget.controller.averageGrade;
      final totalGrades = widget.controller.grades.length;
      final subjects = widget.controller.gradesBySubject.keys.length;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFA855F7).withOpacity(0.8),
              const Color(0xFF6366F1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'overall_average'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    average.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80,
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMiniStat('grades_short'.tr, totalGrades.toString()),
                    const SizedBox(height: 12),
                    _buildMiniStat('subjects'.tr, subjects.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniStat(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectFilter() {
    return Obx(() {
      final subjects = widget.controller.gradesBySubject.keys.toList();
      if (subjects.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('all'.tr, null),
            ...subjects.map((subject) => _buildFilterChip(subject, subject)),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedSubject == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGradesList() {
    return Obx(() {
      if (widget.controller.isLoadingGrades.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        );
      }

      final gradesBySubject = widget.controller.gradesBySubject;
      if (gradesBySubject.isEmpty) {
        return _buildEmptyState();
      }

      if (_selectedSubject != null) {
        final grades = gradesBySubject[_selectedSubject] ?? [];
        return _buildSingleSubjectView(_selectedSubject!, grades);
      }

      return Column(
        children: gradesBySubject.entries.map((entry) {
          return _buildSubjectCard(entry.key, entry.value);
        }).toList(),
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'no_grades_yet'.tr,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'grades_will_appear_here'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subjectName, List<GradeModel> grades) {
    final average = widget.controller.getSubjectAverage(subjectName);

    List<GradeModel> sortedGrades = List.from(grades);
    if (_sortBy == 'date') {
      sortedGrades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      sortedGrades.sort((a, b) => b.value.compareTo(a.value));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getSubjectColor(subjectName).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  color: _getSubjectColor(subjectName),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            subjectName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            (grades.length == 1)
                ? '${grades.length} ${'grade_singular'.tr}'
                : '${grades.length} ${'grade_plural'.tr}',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedGrades.map((grade) => _buildGradeChip(grade)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSubjectView(String subjectName, List<GradeModel> grades) {
    List<GradeModel> sortedGrades = List.from(grades);
    if (_sortBy == 'date') {
      sortedGrades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      sortedGrades.sort((a, b) => b.value.compareTo(a.value));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(subjectName).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: _getSubjectColor(subjectName),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  subjectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${'average'.tr}: ${widget.controller.getSubjectAverage(subjectName).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _getSubjectColor(subjectName),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...sortedGrades.map((grade) => _buildGradeListItem(grade)),
        ],
      ),
    );
  }

  Widget _buildGradeChip(GradeModel grade) {
    return GestureDetector(
      onTap: () => _showGradeDetails(grade),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getGradeColor(grade.value).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _getGradeColor(grade.value).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              grade.value.toString(),
              style: TextStyle(
                color: _getGradeColor(grade.value),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat('dd.MM').format(grade.createdAt),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeListItem(GradeModel grade) {
    final localeCode = Get.locale?.languageCode ?? 'ro';
    return GestureDetector(
      onTap: () => _showGradeDetails(grade),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                color: _getGradeColor(grade.value).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  grade.value.toString(),
                  style: TextStyle(
                    color: _getGradeColor(grade.value),
                    fontSize: 20,
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
                    _getGradeTypeLabel(grade.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy', localeCode).format(grade.createdAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  void _showGradeDetails(GradeModel grade) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getGradeColor(grade.value).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  grade.value.toString(),
                  style: TextStyle(
                    color: _getGradeColor(grade.value),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              grade.subjectName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getGradeTypeLabel(grade.type),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today, 'date_label'.tr,
                DateFormat('dd MMMM yyyy', Get.locale?.languageCode ?? 'ro').format(grade.createdAt)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getGradeColor(int value) {
    if (value >= 9) return const Color(0xFF10B981);
    if (value >= 7) return const Color(0xFF3B82F6);
    if (value >= 5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getSubjectColor(String subjectName) {
    final colors = [
      const Color(0xFFA855F7),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    return colors[subjectName.hashCode % colors.length];
  }

  String _getGradeTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return 'grade_type_exam'.tr;
      case 'test':
        return 'grade_type_test'.tr;
      case 'homework':
        return 'grade_type_homework'.tr;
      case 'assignment':
        return 'grade_type_assignment'.tr;
      case 'oral':
        return 'grade_type_oral'.tr;
      default:
        return 'grade_type_other'.tr;
    }
  }
}
