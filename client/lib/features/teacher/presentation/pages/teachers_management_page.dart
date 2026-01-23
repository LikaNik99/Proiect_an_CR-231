import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../data/model/teacher_model.dart';

/// Pagină pentru Director - Management Profesori
class TeachersManagementPage extends StatefulWidget {
  final TeacherDashboardController controller;

  const TeachersManagementPage({super.key, required this.controller});

  @override
  State<TeachersManagementPage> createState() => _TeachersManagementPageState();
}

class _TeachersManagementPageState extends State<TeachersManagementPage> {
  final _searchController = TextEditingController();
  String _filterBy = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeacherModel> get _filteredTeachers {
    var teachers = widget.controller.allTeachers.toList();


    if (_filterBy == 'homeroom') {
      teachers = teachers.where((t) => t.isHomeroom).toList();
    } else if (_filterBy == 'regular') {
      teachers = teachers.where((t) => !t.isHomeroom && !t.isDirector).toList();
    }


    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      teachers = teachers.where((t) =>
        t.username.toLowerCase().contains(query) ||
        (t.subject?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        title: const Text(
          'Management Profesori',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStats(),
          Expanded(child: _buildTeachersList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F26),
      child: Column(
        children: [

          Container(
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
                hintText: 'Caută profesor...',
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
          const SizedBox(height: 12),

          Row(
            children: [
              _buildFilterChip('Toți', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Diriginți', 'homeroom'),
              const SizedBox(width: 8),
              _buildFilterChip('Profesori', 'regular'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterBy = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white10,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Obx(() {
      final total = widget.controller.allTeachers.length;
      final homeroom = widget.controller.allTeachers.where((t) => t.isHomeroom).length;
      final regular = total - homeroom - 1;

      return Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1A1F26),
        child: Row(
          children: [
            _buildStatItem('Total', total.toString(), Colors.blue),
            _buildStatItem('Diriginți', homeroom.toString(), Colors.green),
            _buildStatItem('Profesori', regular.toString(), Colors.orange),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachersList() {
    return Obx(() {
      if (widget.controller.isLoadingTeachers.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      final teachers = _filteredTeachers;

      if (teachers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Niciun profesor găsit'
                    : 'Nu există profesori',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: teachers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          return _buildTeacherCard(teacher);
        },
      );
    });
  }

  Widget _buildTeacherCard(TeacherModel teacher) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 24,
            backgroundColor: teacher.isHomeroom
                ? Colors.green.withOpacity(0.2)
                : teacher.isDirector
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
            child: Text(
              teacher.username.isNotEmpty ? teacher.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: teacher.isHomeroom
                    ? Colors.green
                    : teacher.isDirector
                        ? Colors.purple
                        : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teacher.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (teacher.isDirector)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Director',
                          style: TextStyle(color: Colors.purple, fontSize: 10),
                        ),
                      ),
                    if (teacher.isHomeroom && !teacher.isDirector)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Diriginte',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  teacher.subject ?? 'Disciplină nespecificată',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            color: const Color(0xFF1A1F26),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    const Text('Vezi detalii', style: TextStyle(color: Colors.white)),
                  ],
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _showTeacherDetails(teacher),
                ),
              ),
              if (!teacher.isDirector)
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        teacher.isHomeroom ? Icons.remove_circle : Icons.school,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        teacher.isHomeroom ? 'Elimină diriginte' : 'Setează diriginte',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => _toggleHomeroom(teacher),
                  ),
                ),
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    const Text('Trimite mesaj', style: TextStyle(color: Colors.white)),
                  ],
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _sendMessage(teacher),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTeacherDetails(TeacherModel teacher) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                teacher.username,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', teacher.id),
            _buildDetailRow('Disciplină', teacher.subject ?? 'N/A'),
            _buildDetailRow('Status', teacher.isDirector
                ? 'Director'
                : teacher.isHomeroom
                    ? 'Diriginte'
                    : 'Profesor'),
            if (teacher.isHomeroom && teacher.classes.isNotEmpty)
              _buildDetailRow('Clasă diriginte', teacher.classes.first.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Închide', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHomeroom(TeacherModel teacher) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          teacher.isHomeroom ? 'Elimină diriginte' : 'Setează diriginte',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          teacher.isHomeroom
              ? 'Ești sigur că vrei să elimini statutul de diriginte pentru ${teacher.username}?'
              : 'Selectează clasa pentru care ${teacher.username} va fi diriginte.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Succes',
                teacher.isHomeroom
                    ? 'Status de diriginte eliminat'
                    : 'Diriginte setat cu succes',
                backgroundColor: Colors.green.withOpacity(0.2),
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teacher.isHomeroom ? Colors.red : Colors.green,
            ),
            child: Text(
              teacher.isHomeroom ? 'Elimină' : 'Setează',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(TeacherModel teacher) {
    final messageController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Trimite mesaj către ${teacher.username}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: messageController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Scrie mesajul...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFF0F1419),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Anulează', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isEmpty) return;
              Get.back();
              Get.snackbar(
                'Succes',
                'Mesaj trimis către ${teacher.username}',
                backgroundColor: Colors.green.withOpacity(0.2),
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Trimite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
