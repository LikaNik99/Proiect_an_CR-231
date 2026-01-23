import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/schedule_entity.dart';
import '../pages/teacher_notifications_page.dart';
import 'class_details_page.dart';

class HomeTabFinal extends StatelessWidget {
  final TeacherDashboardController controller;

  const HomeTabFinal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchCurrentTeacher();
      },
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildNextClassCard()),
          SliverToBoxAdapter(child: _buildTodaySchedule()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final teacher = controller.teacher.value;
          if (teacher == null) return const SizedBox(height: 100);

          final hour = DateTime.now().hour;
          String greeting = hour < 12
              ? 'Bună dimineața'
              : hour < 18
              ? 'Bună ziua'
              : 'Bună seara';

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher.username,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (teacher.subject != null)
                      Text(
                        teacher.subject!,
                        style: TextStyle(
                          color: Colors.blueAccent.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () => Get.to(() => TeacherNotificationsPage(controller: controller)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.2),
                      Colors.blueAccent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM',
                        'ro',
                      ).format(DateTime.now()).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.class_,
                    label: 'Clase',
                    value: '${controller.totalClasses}',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    label: 'Elevi',
                    value: '${controller.totalStudents}',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    label: 'Ore azi',
                    value: '${controller.lessonsToday}',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildNextClassCard() {
    return Obx(() {
      final currentLesson = controller.currentLesson;
      final nextLesson = controller.nextLesson;


      final lesson = currentLesson ?? nextLesson;
      final isCurrent = currentLesson != null;

      if (lesson == null) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[900]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nu ai ore programate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Bucură-te de timp liber!",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final className = controller.getClassName(lesson.classId);
      final gradient = isCurrent
          ? [const Color(0xFF10B981), const Color(0xFF059669)]
          : [Colors.blueAccent, Colors.blue];

      return GestureDetector(
        onTap: () {
          final schoolClass = controller.classes.firstWhereOrNull(
            (c) => c.id == lesson.classId,
          );
          if (schoolClass != null) {
            Get.to(
              () => ClassDetailsPage(
                schoolClass: schoolClass,
                controller: controller,
              ),
              transition: Transition.rightToLeft,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCurrent ? Icons.play_circle : Icons.schedule,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrent ? "Ora curentă" : "Următoarea oră",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$className - ${lesson.subjectName ?? 'Materie'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${lesson.startTime} - ${lesson.endTime}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        if (lesson.room != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.room,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.room!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.getTimeUntilLesson(lesson),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTodaySchedule() {
    return Obx(() {
      final todayLessons = controller.todaySchedule;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Orarul de azi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.getDayNameRomanian(controller.getTodayEnum()),
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (todayLessons.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF252B35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nu ai ore programate astăzi',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              ...todayLessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                final isCurrent = controller.currentLesson?.id == lesson.id;

                return _buildScheduleItem(
                  lesson,
                  isCurrent,
                  index == todayLessons.length - 1,
                );
              }),
          ],
        ),
      );
    });
  }

  Widget _buildScheduleItem(Schedule lesson, bool isCurrent, bool isLast) {
    final className = controller.getClassName(lesson.classId);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: IntrinsicHeight(
        child: Row(
          children: [

            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF10B981)
                        : Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(width: 16),

            Expanded(
              child: GestureDetector(
                onTap: () {
                  final schoolClass = controller.classes.firstWhereOrNull(
                    (c) => c.id == lesson.classId,
                  );
                  if (schoolClass != null) {
                    Get.to(
                      () => ClassDetailsPage(
                        schoolClass: schoolClass,
                        controller: controller,
                      ),
                      transition: Transition.rightToLeft,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFF252B35),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.startTime,
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              lesson.endTime,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[700],
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (lesson.room != null)
                              Text(
                                'Sala ${lesson.room}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ACUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[600],
                          size: 14,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
