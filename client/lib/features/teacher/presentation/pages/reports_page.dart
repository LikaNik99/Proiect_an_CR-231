import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';

class ReportsPage extends StatelessWidget {
  final TeacherDashboardController controller;

  const ReportsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: FutureBuilder<Map<String, dynamic>>(
        future: controller.fetchSchoolOverviewReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    'Se încarcă raportul...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Eroare la încărcarea raportului',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text('Înapoi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final schoolStats = data['school_statistics'] as Map<String, dynamic>;
          final classes = data['classes'] as List<dynamic>;

          return CustomScrollView(
            slivers: [

              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1A1F26),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Rapoarte Școală',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),


              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Statistici Generale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStatCard(
                                'Clase',
                                schoolStats['total_classes'].toString(),
                                Icons.class_rounded,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                'Elevi',
                                schoolStats['total_students'].toString(),
                                Icons.people_rounded,
                                Colors.purple,
                              ),
                              _buildStatCard(
                                'Profesori',
                                schoolStats['total_teachers'].toString(),
                                Icons.person_rounded,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'Medie',
                                double.parse(schoolStats['average_grade'].toString()).toStringAsFixed(2),
                                Icons.grade_rounded,
                                Colors.green,
                              ),
                              _buildStatCard(
                                'Note',
                                schoolStats['total_grades'].toString(),
                                Icons.assignment_rounded,
                                Colors.pink,
                              ),
                              _buildStatCard(
                                'Prezență',
                                '${schoolStats['attendance_rate']}%',
                                Icons.check_circle_rounded,
                                Colors.teal,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),


                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Performanță pe Clase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),


                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final classData = classes[index];
                          final avgGrade = classData['average_grade'] as num;
                          final gradeColor = avgGrade >= 8.5
                              ? Colors.green
                              : avgGrade >= 7.0
                                  ? Colors.blue
                                  : avgGrade >= 5.0
                                      ? Colors.orange
                                      : Colors.red;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gradeColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: gradeColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      avgGrade > 0 ? avgGrade.toStringAsFixed(1) : '-',
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                        classData['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${classData['total_students']} elevi • ${classData['attendance_rate']}% prezență',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${classData['total_grades']} note înregistrate',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: gradeColor,
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        avgGrade > 0 ? avgGrade.toStringAsFixed(2) : 'N/A',
                                        style: TextStyle(
                                          color: gradeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
