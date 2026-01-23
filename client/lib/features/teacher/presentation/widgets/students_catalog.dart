import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../student/data/model/student.dart';
import '../../data/model/teacher_model.dart';
import '../../domain/entities/attendance_entity.dart';
import '../controllers/teacher_dashboard_controller.dart';
import 'student_details_widgets.dart';

class StudentsCatalog extends StatefulWidget {
  final SchoolClass schoolClass;
  final TeacherDashboardController controller;

  const StudentsCatalog({
    super.key,
    required this.schoolClass,
    required this.controller,
  });

  @override
  State<StudentsCatalog> createState() => _StudentsCatalogState();
}

class _StudentsCatalogState extends State<StudentsCatalog> {
  late TextEditingController _searchController;
  final List<StudentModel> _selectedStudents = [];
  DateTime _selectedDate = DateTime.now();


  int _activeSection = 0;


  String _sortBy = 'name';
  bool _showTutorial = false;


  String? get _disciplineName => widget.controller.getSubjectNameForClass(widget.schoolClass.id);
  String get _teacherName => widget.controller.teacher.value?.username ?? 'Profesor';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadAttendanceForDate();
  }


  void _loadAttendanceForDate() async {
    final studentIds = widget.schoolClass.students
        .map((s) => s.userId)
        .whereType<String>()
        .toList();

    for (final sid in studentIds) {
      await widget.controller.fetchStudentAttendance(sid);
    }

    if (mounted) setState(() {});
  }


  void _selectAll() {
    setState(() {
      _selectedStudents.clear();
      _selectedStudents.addAll(_filteredStudents);
    });
    _showSnackbar('${_selectedStudents.length} elevi selectați', Icons.check_circle);
  }


  void _deselectAll() {
    setState(() {
      _selectedStudents.clear();
    });
    _showSnackbar('Selecție anulată', Icons.clear);
  }


  void _toggleStudent(StudentModel student) {
    setState(() {
      if (_selectedStudents.contains(student)) {
        _selectedStudents.remove(student);
      } else {
        _selectedStudents.add(student);
      }
    });
  }


  void _showSnackbar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1A1F26),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentModel> get _filteredStudents {
    List<StudentModel> students = List.from(widget.schoolClass.students);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      students = students
          .where(
            (student) =>
                student.username.toLowerCase().contains(query) ||
                student.email.toLowerCase().contains(query),
          )
          .toList();
    }


    if (_sortBy == 'name') {
      students.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (_sortBy == 'email') {
      students.sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
    }

    return students;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F26),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1F26),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);

      _loadAttendanceForDate();
    }
  }

  Map<String, String>? get _currentSelectedSubject {
    final classId = widget.schoolClass.id;
    final selected = widget.controller.selectedSubjectByClassId[classId];
    if (selected == null || (selected['id'] ?? '').isEmpty) return null;
    return {'id': selected['id']!, 'name': selected['name'] ?? 'Necunoscut'};
  }

  List<Map<String, String>> get _subjectsForThisClass {

    final fromClass = widget.schoolClass.subjects
        .where((s) => s.id.isNotEmpty)
        .map((s) => {'id': s.id, 'name': s.name})
        .toList();
    if (fromClass.isNotEmpty) return fromClass;


    try {
      return widget.controller.getSubjectsForClass(widget.schoolClass.id);
    } catch (_) {
      return [];
    }
  }

  Future<void> _ensureSubjectSelectedForActions() async {

    if (widget.controller.teacherSchedules.isEmpty) {
      await widget.controller.fetchTeacherSchedule();
    }


    await widget.controller.fetchMySubjectsForClass(widget.schoolClass.id);

    final subjects = _subjectsForThisClass;
    if (subjects.isEmpty) {
      return;
    }


    final current = _currentSelectedSubject;
    if (current != null && subjects.any((s) => s['id'] == current['id'])) {
      return;
    }


    if (subjects.length == 1) {
      widget.controller.setSelectedSubjectForClass(
        widget.schoolClass.id,
        subjectId: subjects.first['id']!,
        subjectName: subjects.first['name']!,
      );
      return;
    }


    final picked = await _showPickSubjectDialog(subjects);
    if (picked != null && (picked['id'] ?? '').isNotEmpty) {
      widget.controller.setSelectedSubjectForClass(
        widget.schoolClass.id,
        subjectId: picked['id']!,
        subjectName: picked['name'] ?? 'Necunoscut',
      );
    }
  }


  Future<void> _ensureSubjectSelected() async {
    final classId = widget.schoolClass.id;


    if (widget.controller.teacherSchedules.isEmpty) {
      await widget.controller.fetchTeacherSchedule();
    }


    await widget.controller.fetchMySubjectsForClass(classId);

    final subjects = widget.controller.getSubjectsForClass(classId);
    if (subjects.isEmpty) {

      await widget.controller.fetchClassSchedule(classId);
      final subjects2 = widget.controller.getSubjectsForClass(classId);
      if (subjects2.isEmpty) return;
      if (subjects2.length == 1) {
        widget.controller.setSelectedSubjectForClass(
          classId,
          subjectId: subjects2.first['id']!,
          subjectName: subjects2.first['name']!,
        );
        return;
      }
      await _showPickSubjectDialog(subjects2);
      return;
    }


    final current = _currentSelectedSubject;
    if (current != null && subjects.any((s) => s['id'] == current['id'])) {
      return;
    }


    if (subjects.length == 1) {
      widget.controller.setSelectedSubjectForClass(
        classId,
        subjectId: subjects.first['id']!,
        subjectName: subjects.first['name']!,
      );
      return;
    }


    final already = widget.controller.selectedSubjectByClassId[classId];
    if (already != null && (already['id'] ?? '').isNotEmpty) {
      return;
    }

    await _showPickSubjectDialog(subjects);
  }

  Future<Map<String, String>?> _showPickSubjectDialog(List<Map<String, String>> subjects) async {
    final classId = widget.schoolClass.id;

    return await Get.dialog<Map<String, String>>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Alege disciplina', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: subjects
              .map(
                (s) => ListTile(
                  title: Text(s['name'] ?? 'Necunoscut', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    widget.controller.setSelectedSubjectForClass(
                      classId,
                      subjectId: s['id'] ?? '',
                      subjectName: s['name'] ?? 'Necunoscut',
                    );
                    Get.back(result: s);
                    setState(() {});
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<String?> _getSubjectId() async {
    final classId = widget.schoolClass.id;

    await _ensureSubjectSelectedForActions();

    final subjectId = widget.controller.getSubjectIdForClass(classId) ?? await widget.controller.resolveSubjectIdForClass(classId);

    if (subjectId == null || subjectId.isEmpty) {
      Get.snackbar('Eroare', 'Nu s-a putut determina materia pentru această clasă');
      return null;
    }

    return subjectId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Catalog',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildHeaderWithSubjectDropdown(),
          _buildTopTabs(),
          Expanded(child: _buildSectionBody()),
          if (_selectedStudents.isNotEmpty && _activeSection == 0) _buildBulkActionBar(),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildTabButton('Elevi', 0),
          _buildTabButton('Note', 1),
          _buildTabButton('Absențe', 2),
          _buildTabButton('Teme', 3),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final active = _activeSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _activeSection = index);
          if (index != 0) {

            await _ensureSubjectSelected();
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionBody() {
    switch (_activeSection) {
      case 0:
        return Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildStudentsList()),
          ],
        );
      case 1:
        return _buildClassGradesView();
      case 2:
        return _buildClassAttendanceView();
      case 3:
        return _buildClassHomeworkView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClassGradesView() {
    final classStudentIds = widget.schoolClass.students.map((s) => s.userId).whereType<String>().toSet();
    final classId = widget.schoolClass.id;
    final subjectId = widget.controller.getSubjectIdForClass(classId);

    final filtered = widget.controller.grades.where((g) {
      final sid = g.studentId;
      if (sid == null) return false;
      if (!classStudentIds.contains(sid)) return false;
      if (subjectId != null && subjectId.isNotEmpty && g.subjectId != subjectId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async {
        await _ensureSubjectSelected();
        await widget.controller.fetchTeacherGrades();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: filtered.isEmpty ? 1 : filtered.length,
        itemBuilder: (context, index) {
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Nu există note pentru această clasă', style: TextStyle(color: Colors.grey[400])),
              ),
            );
          }

          final g = filtered[index];
          final student = widget.schoolClass.students.firstWhereOrNull((s) => s.userId == g.studentId);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      g.value.toString(),
                      style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student?.username ?? 'Elev', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${g.subjectName ?? _disciplineName ?? ''} • ${g.type.name}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd.MM').format(g.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassHomeworkView() {
    return Stack(
      children: [
        FutureBuilder<void>(
          future: widget.controller.fetchClassHomework(widget.schoolClass.id),
          builder: (context, snapshot) {
            final items = widget.controller.homeworkList;
            if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Nu există teme pentru această clasă',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apasă butonul + pentru a adăuga',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final h = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(h.description ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[500], size: 14),
                          const SizedBox(width: 6),
                          Text(DateFormat('dd MMM yyyy', 'ro').format(h.dueDate), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          const Spacer(),
                          if (h.assignedStudentIds.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blue, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${h.assignedStudentIds.length} elev${h.assignedStudentIds.length != 1 ? 'i' : ''}',
                                    style: const TextStyle(color: Colors.blue, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showClassHomeworkDialog(),
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildClassAttendanceView() {
    return FutureBuilder<List<Attendance>>(
      future: _loadClassAttendance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text('Nu există absențe/prezențe pentru această clasă', style: TextStyle(color: Colors.grey[400])));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final a = list[index];
            final student = widget.schoolClass.students.firstWhereOrNull((s) => s.userId == a.studentId);
            final color = a.status == AttendanceStatus.absent ? Colors.red : Colors.green;
            final label = a.status == AttendanceStatus.absent ? 'Absent' : 'Prezent';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student?.username ?? 'Elev', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(DateFormat('dd.MM').format(a.attendanceDate), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Attendance>> _loadClassAttendance() async {
    await _ensureSubjectSelected();
    final subjectId = widget.controller.getSubjectIdForClass(widget.schoolClass.id);
    final tokenStudentIds = widget.schoolClass.students.map((s) => s.userId).whereType<String>().toList();

    final all = <Attendance>[];
    for (final sid in tokenStudentIds) {
      await widget.controller.fetchStudentAttendance(sid);
      all.addAll(widget.controller.attendanceList);
    }

    final filtered = all.where((a) {
      if (subjectId != null && subjectId.isNotEmpty && a.subjectId != subjectId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

    return filtered;
  }

  void _showHomeworkDialog(StudentModel student) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Temă pentru ${student.username}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Titlu',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Descriere',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final subjectId = await _getSubjectId();
              if (subjectId == null) return;

              final ids = [if (student.userId != null) student.userId!];
              await widget.controller.createHomeworkForStudents(
                studentIds: ids,
                classId: widget.schoolClass.id,
                subjectId: subjectId,
                title: titleController.text,
                description: descriptionController.text,
                dueDate: _selectedDate,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Trimite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClassHomeworkDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.class_, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temă pentru întreaga clasă',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    widget.schoolClass.name,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Această temă va fi trimisă tuturor celor ${widget.schoolClass.students.length} elevi din clasă',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Titlu temă',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0F1419),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Descriere (ex: Rezolvați exercițiile 1-10 din manual)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0F1419),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.description, color: Colors.grey),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Termen limită: ${DateFormat('dd MMMM yyyy', 'ro').format(_selectedDate)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                Get.snackbar('Eroare', 'Te rog introdu un titlu pentru temă');
                return;
              }

              final subjectId = await _getSubjectId();
              if (subjectId == null) return;


              final studentIds = widget.schoolClass.students
                  .map((s) => s.userId)
                  .whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .toList();

              if (studentIds.isEmpty) {
                Get.snackbar('Eroare', 'Nu există elevi în această clasă');
                return;
              }

              await widget.controller.createHomeworkForStudents(
                studentIds: studentIds,
                classId: widget.schoolClass.id,
                subjectId: subjectId,
                title: titleController.text,
                description: descriptionController.text,
                dueDate: _selectedDate,
              );

              Get.back();


              setState(() {});

              Get.snackbar(
                'Succes',
                'Tema a fost trimisă la ${studentIds.length} elev${studentIds.length != 1 ? 'i' : ''}',
                backgroundColor: Colors.green.withOpacity(0.2),
                colorText: Colors.white,
                icon: const Icon(Icons.check_circle, color: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Trimite tema', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedStudents.length} elev${_selectedStudents.length > 1 ? "i" : ""} selectat${_selectedStudents.length > 1 ? "i" : ""}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBulkGradeDialog,
                    icon: const Icon(Icons.grade, size: 20),
                    label: const Text('Notă'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBulkAttendanceDialog,
                    icon: const Icon(Icons.event_busy, size: 20),
                    label: const Text('Absență'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBulkHomeworkDialog,
                    icon: const Icon(Icons.assignment, size: 20),
                    label: const Text('Temă'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _deselectAll,
              child: const Text('Anulează selecția', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkGradeDialog() {
    final gradeController = TextEditingController();
    String gradeType = 'other';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Notă pentru ${_selectedStudents.length} elevi',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: gradeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '2-10',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gradeType,
                  dropdownColor: const Color(0xFF1A1F26),
                  decoration: InputDecoration(
                    labelText: 'Tip notă',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'exam', child: Text('Teză', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'test', child: Text('Test', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'homework', child: Text('Temă', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'assignment', child: Text('Lucrare', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'other', child: Text('Altele', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setDialogState(() => gradeType = v ?? 'other'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final grade = int.tryParse(gradeController.text);
                  if (grade == null || grade < 2 || grade > 10) {
                    Get.snackbar('Eroare', 'Introdu o notă validă (2-10)');
                    return;
                  }

                  final subjectId = await _getSubjectId();
                  if (subjectId == null) return;

                  final ids = _selectedStudents.map((s) => s.userId).whereType<String>().toList();
                  await widget.controller.createGradesForStudents(
                    studentIds: ids,
                    value: grade,
                    type: gradeType,
                    classId: widget.schoolClass.id,
                    subjectId: subjectId,
                  );

                  Get.back();
                  _deselectAll();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Salvează', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkHomeworkDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Temă pentru ${_selectedStudents.length} elevi',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Titlu',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Descriere',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final subjectId = await _getSubjectId();
              if (subjectId == null) return;

              final ids = _selectedStudents.map((s) => s.userId).whereType<String>().toList();
              await widget.controller.createHomeworkForStudents(
                studentIds: ids,
                classId: widget.schoolClass.id,
                subjectId: subjectId,
                title: titleController.text,
                description: descriptionController.text,
                dueDate: _selectedDate,
              );
              Get.back();
              _deselectAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Trimite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBulkAttendanceDialog() {
    String status = 'present';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Prezență pentru ${_selectedStudents.length} elevi',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'ro').format(_selectedDate),
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: const Color(0xFF1A1F26),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'present', child: Text('Prezent', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'absent', child: Text('Absent', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setDialogState(() => status = v ?? 'present'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ids = _selectedStudents.map((s) => s.userId).whereType<String>().toList();

                  final subjectId = await _getSubjectId();
                  if (subjectId == null) return;

                  final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final data = {
                    'status': status,
                    'attendance_date': dateStr,
                    'subject_id': subjectId,
                    'class_id': widget.schoolClass.id,
                  };

                  for (final id in ids) {
                    if (id.isNotEmpty) {
                      await widget.controller.markAttendanceForStudent(
                        studentId: id,
                        subjectId: subjectId,
                        date: _selectedDate,
                        status: status,
                        notes: null,
                      );
                    }
                  }

                  _deselectAll();
                  Get.back();

                  Get.snackbar(
                    'Succes',
                    'Prezența a fost actualizată pentru ${ids.length} elevi',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Salvează', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickAttendanceDialog(StudentModel student) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Prezență: ${student.username}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('dd MMMM yyyy', 'ro').format(_selectedDate),
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              'Selectează status (default: Prezent)',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildAttendanceOption(
                    'Prezent',
                    Colors.green,
                    Icons.check_circle,
                    isDefault: true,
                    onTap: () async {
                      Get.back();
                      final subjectId = await _getSubjectId();
                      if (subjectId == null) return;

                      final sid = student.userId;
                      if (sid == null || sid.isEmpty) return;

                      await widget.controller.markAttendanceForStudent(
                        studentId: sid,
                        subjectId: subjectId,
                        date: _selectedDate,
                        status: 'present',
                        notes: null,
                      );


                      await widget.controller.fetchStudentAttendance(sid);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAttendanceOption(
                    'Absent',
                    Colors.red,
                    Icons.cancel,
                    isDefault: false,
                    onTap: () async {
                      Get.back();
                      final subjectId = await _getSubjectId();
                      if (subjectId == null) return;

                      final sid = student.userId;
                      if (sid == null || sid.isEmpty) return;

                      await widget.controller.markAttendanceForStudent(
                        studentId: sid,
                        subjectId: subjectId,
                        date: _selectedDate,
                        status: 'absent',
                        notes: null,
                      );


                      await widget.controller.fetchStudentAttendance(sid);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildAttendanceOption(
                    'Întârziat',
                    Colors.orange,
                    Icons.schedule,
                    isDefault: false,
                    onTap: () async {
                      Get.back();
                      final subjectId = await _getSubjectId();
                      if (subjectId == null) return;

                      final sid = student.userId;
                      if (sid == null || sid.isEmpty) return;

                      await widget.controller.markAttendanceForStudent(
                        studentId: sid,
                        subjectId: subjectId,
                        date: _selectedDate,
                        status: 'late',
                        notes: null,
                      );


                      await widget.controller.fetchStudentAttendance(sid);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAttendanceOption(
                    'Motivat',
                    Colors.blue,
                    Icons.event_available,
                    isDefault: false,
                    onTap: () async {
                      Get.back();
                      final subjectId = await _getSubjectId();
                      if (subjectId == null) return;

                      final sid = student.userId;
                      if (sid == null || sid.isEmpty) return;

                      await widget.controller.markAttendanceForStudent(
                        studentId: sid,
                        subjectId: subjectId,
                        date: _selectedDate,
                        status: 'excused',
                        notes: null,
                      );


                      await widget.controller.fetchStudentAttendance(sid);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceOption(
    String label,
    Color color,
    IconData icon,
    {bool isDefault = false,
    required VoidCallback onTap}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDefault ? color.withOpacity(0.25) : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: isDefault ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isDefault ? 32 : 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: isDefault ? 14 : 13,
                  fontWeight: isDefault ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (isDefault)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStudentDetails(StudentModel student) {
    Get.to(() => StudentDetailsPage(
      student: student,
      controller: widget.controller,
      classId: widget.schoolClass.id,
      disciplineName: _disciplineName,
      teacherName: _teacherName,
      onAddGrade: () => _showAddGradeDialog(student),
      onAddAbsence: () => _showQuickAttendanceDialog(student),
    ));
  }

  Widget _buildAttendanceStatusAvatar(StudentModel student) {

    final studentId = student.userId;
    if (studentId == null || studentId.isEmpty) {

      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        child: Text(
          student.username.isNotEmpty ? student.username[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      );
    }


    Attendance? attendanceForStudent;
    try {
      attendanceForStudent = widget.controller.attendanceList.firstWhereOrNull(
        (a) =>
          a.studentId == studentId &&
          a.attendanceDate.year == _selectedDate.year &&
          a.attendanceDate.month == _selectedDate.month &&
          a.attendanceDate.day == _selectedDate.day,
      );
    } catch (e) {
      print('Error finding attendance: $e');
    }


    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (attendanceForStudent != null) {
      switch (attendanceForStudent.status) {
        case AttendanceStatus.present:
          statusColor = const Color(0xFF4CAF50);
          statusIcon = Icons.check_circle;
          break;
        case AttendanceStatus.absent:
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.cancel;
          break;
        case AttendanceStatus.late:
          statusColor = const Color(0xFFFF9800);
          statusIcon = Icons.schedule;
          break;
        case AttendanceStatus.excused:
          statusColor = const Color(0xFF2196F3);
          statusIcon = Icons.event_available;
          break;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: Text(
            student.username.isNotEmpty ? student.username[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),

        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0F1419),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                statusIcon,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(StudentModel student) {

    final studentId = student.userId;
    if (studentId == null || studentId.isEmpty) {

      return IconButton(
        icon: const Icon(Icons.event_busy, color: Colors.red, size: 22),
        onPressed: () => _showQuickAttendanceDialog(student),
        tooltip: 'Prezență',
      );
    }


    Attendance? attendanceForStudent;
    try {
      attendanceForStudent = widget.controller.attendanceList.firstWhereOrNull(
        (a) =>
          a.studentId == studentId &&
          a.attendanceDate.year == _selectedDate.year &&
          a.attendanceDate.month == _selectedDate.month &&
          a.attendanceDate.day == _selectedDate.day,
      );
    } catch (e) {
      print('Error finding attendance for button: $e');
    }


    Color buttonColor;
    IconData buttonIcon;
    String buttonTooltip;

    if (attendanceForStudent == null) {

      buttonColor = Colors.grey;
      buttonIcon = Icons.help_outline;
      buttonTooltip = 'Prezență (Nemarcat)';
    } else {
      switch (attendanceForStudent.status) {
        case AttendanceStatus.present:
          buttonColor = const Color(0xFF4CAF50);
          buttonIcon = Icons.check_circle;
          buttonTooltip = 'Prezent';
          break;
        case AttendanceStatus.absent:
          buttonColor = const Color(0xFFEF4444);
          buttonIcon = Icons.cancel;
          buttonTooltip = 'Absent';
          break;
        case AttendanceStatus.late:
          buttonColor = const Color(0xFFFF9800);
          buttonIcon = Icons.schedule;
          buttonTooltip = 'Întârziat';
          break;
        case AttendanceStatus.excused:
          buttonColor = const Color(0xFF2196F3);
          buttonIcon = Icons.event_available;
          buttonTooltip = 'Motivat';
          break;
      }
    }

    return IconButton(
      icon: Icon(buttonIcon, color: buttonColor, size: 22),
      onPressed: () => _showQuickAttendanceDialog(student),
      tooltip: buttonTooltip,
    );
  }


  Widget _buildSimpleHeader() {
    final discipline = _disciplineName ?? 'Nespecificat';
    final dateStr = DateFormat('dd MMM yyyy', 'ro').format(_selectedDate);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.schoolClass.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.book, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        discipline,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithSubjectDropdown() {
    final dateStr = DateFormat('dd MMM yyyy', 'ro').format(_selectedDate);
    final subjects = _subjectsForThisClass;
    final selected = _currentSelectedSubject;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.schoolClass.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1F26),
                      value: (selected != null && subjects.any((s) => s['id'] == selected['id'])) ? selected['id'] : (subjects.length == 1 ? subjects.first['id'] : null),
                      hint: Text(
                        subjects.isEmpty ? 'Fără disciplină în orar' : 'Alege disciplina',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      items: subjects
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s['id'],
                              child: Text(
                                s['name'] ?? 'Necunoscut',
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: subjects.isEmpty
                          ? null
                          : (id) {
                              final picked = subjects.firstWhereOrNull((s) => s['id'] == id);
                              if (picked == null || (picked['id'] ?? '').isEmpty) return;
                              widget.controller.setSelectedSubjectForClass(
                                widget.schoolClass.id,
                                subjectId: picked['id']!,
                                subjectName: picked['name'] ?? 'Necunoscut',
                              );
                              setState(() {});
                            },
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Caută elev...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
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
    );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'Nu sunt elevi în această clasă' : 'Niciun rezultat',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredStudents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final isSelected = _selectedStudents.contains(student);

        return InkWell(
          onTap: () {
            if (_selectedStudents.isNotEmpty) {
              setState(() {
                if (isSelected) {
                  _selectedStudents.remove(student);
                } else {
                  _selectedStudents.add(student);
                }
              });
            }
          },
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedStudents.remove(student);
              } else {
                _selectedStudents.add(student);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.15) : const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.blueAccent.withOpacity(0.5) : Colors.white10),
            ),
            child: Row(
              children: [
                if (_selectedStudents.isNotEmpty)
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedStudents.add(student);
                        } else {
                          _selectedStudents.remove(student);
                        }
                      });
                    },
                    activeColor: Colors.blueAccent,
                  )
                else
                  _buildAttendanceStatusAvatar(student),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.username,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_selectedStudents.isEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.grade, color: Colors.orange, size: 22),
                    onPressed: () => _showAddGradeDialog(student),
                    tooltip: 'Notă',
                  ),
                  _buildAttendanceButton(student),
                  IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.blue, size: 22),
                    onPressed: () => _showHomeworkDialog(student),
                    tooltip: 'Temă',
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: const Color(0xFF1A1F26),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 10),
                            const Text('Vezi detalii', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () => Future.delayed(Duration.zero, () => _openStudentDetails(student)),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.assignment, color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            const Text('Temă', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () => Future.delayed(Duration.zero, () => _showHomeworkDialog(student)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }


  void _showAddGradeDialog(StudentModel student) async {
    final gradeController = TextEditingController();
    String gradeType = 'other';

    final subjectId = await _getSubjectId();
    if (subjectId == null) return;

    final subjectName = widget.controller.getSubjectNameForClass(widget.schoolClass.id);

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Notă pentru ${student.username}', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subjectName != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.book, color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(subjectName, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: gradeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '2-10',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gradeType,
                  dropdownColor: const Color(0xFF1A1F26),
                  decoration: InputDecoration(
                    labelText: 'Tip notă',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'exam', child: Text('Teză', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'test', child: Text('Test', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'homework', child: Text('Temă', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'assignment', child: Text('Lucrare', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'other', child: Text('Altele', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setDialogState(() => gradeType = v ?? 'other'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final grade = int.tryParse(gradeController.text);
                  if (grade == null || grade < 2 || grade > 10) {
                    Get.snackbar('Eroare', 'Introdu o notă validă (2-10)');
                    return;
                  }

                  final sid = student.userId;
                  if (sid == null || sid.isEmpty) return;


                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }

                  try {
                    await widget.controller.createGradesForStudents(
                      studentIds: [sid],
                      value: grade,
                      type: gradeType,
                      classId: widget.schoolClass.id,
                      subjectId: subjectId,
                    );
                  } catch (e) {
                    Get.snackbar('Eroare', 'Nu s-a putut salva nota: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Salvează', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
