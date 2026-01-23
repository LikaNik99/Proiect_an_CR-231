import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import 'class_details_page.dart';

class ClassesTab extends StatefulWidget {
  final TeacherDashboardController controller;

  const ClassesTab({super.key, required this.controller});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              spacing: 16,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clasele mele',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            '${widget.controller.classes.length} clase • ${widget.controller.allStudents.length} elevi',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.class_,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[700]!.withOpacity(0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Caută clasă...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              final classes = widget.controller.classes;
              final filteredClasses = classes
                  .where(
                    (cls) => cls.name.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ),
                  )
                  .toList();

              if (classes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Nu aveți clase asignate',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              if (filteredClasses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Niciun rezultat pentru "${_searchController.text}"',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredClasses.length,
                itemBuilder: (context, index) {
                  final schoolClass = filteredClasses[index];
                  return _buildClassCard(context, schoolClass);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic schoolClass) {
    final studentCount = schoolClass.students.length;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ClassDetailsPage(
            schoolClass: schoolClass,
            controller: widget.controller,
          ),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.25),
                        Colors.blueAccent.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      schoolClass.name[0],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        schoolClass.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      Builder(
                        builder: (_) {
                          final subs = (schoolClass.subjects as List?) ?? const [];
                          final names = subs
                              .map((s) => (s.name ?? '').toString())
                              .where((n) => n.trim().isNotEmpty)
                              .toList();

                          final display = names.isNotEmpty
                              ? names.join(', ')
                              : 'Nespecificată';

                          return Text(
                            'Materii: $display',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ],
            ),

            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: _buildClassStatChip(
                    Icons.people_rounded,
                    '$studentCount',
                    'Elevi',
                    Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: _buildClassStatChip(
                    Icons.grade_rounded,
                    '0',
                    'Medii',
                    Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildClassStatChip(
                    Icons.assignment_rounded,
                    '0',
                    'Teme',
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        spacing: 4,
        children: [
          Icon(icon, size: 16, color: color),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ));
  }
}
