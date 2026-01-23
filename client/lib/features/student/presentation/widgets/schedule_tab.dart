import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_dashboard_controller.dart';
import '../../data/model/schedule_model.dart';

class ScheduleTab extends StatefulWidget {
  final StudentDashboardController controller;

  const ScheduleTab({super.key, required this.controller});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late int _selectedDayIndex;

  final List<String> _dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedDayIndex = today <= 5 ? today - 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => widget.controller.fetchSchedule(forceRefresh: true),
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A1F26),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildDaySelector()),
          SliverToBoxAdapter(child: _buildScheduleList()),
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
              'schedule_title'.tr,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.today, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _dayKeys[_selectedDayIndex].tr,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final isSelected = _selectedDayIndex == index;
          final isToday = DateTime.now().weekday - 1 == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayKeys[index].tr.substring(0, 2),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isToday)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Obx(() {
      if (widget.controller.isLoadingSchedule.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        );
      }

      final schedules = widget.controller.getScheduleForDay(_dayKeys[_selectedDayIndex]);

      if (schedules.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: schedules.asMap().entries.map((entry) {
          final index = entry.key;
          final schedule = entry.value;
          final isCurrentLesson = _isCurrentLesson(schedule);

          return _buildScheduleCard(schedule, index, isCurrentLesson);
        }).toList(),
      );
    });
  }

  bool _isCurrentLesson(ScheduleModel schedule) {
    final now = DateTime.now();
    final today = DateTime.now().weekday;
    if (today != _selectedDayIndex + 1) return false;

    final startParts = schedule.startTime.split(':');
    final endParts = schedule.endTime.split(':');

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    return now.isAfter(startTime) && now.isBefore(endTime);
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
            Icons.weekend_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'free_day'.tr,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_classes_today'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule, int index, bool isCurrentLesson) {
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
    final color = colors[schedule.subjectName.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  schedule.startTime,
                  style: TextStyle(
                    color: isCurrentLesson ? Colors.blueAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.endTime,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isCurrentLesson ? Colors.blueAccent : color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentLesson ? Colors.blueAccent : color,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: color.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(16),
                border: isCurrentLesson
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : null,
                boxShadow: isCurrentLesson
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.subjectName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'period_label'.trParams({'period': schedule.periodNumber.toString()}),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentLesson)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'now'.tr,
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
