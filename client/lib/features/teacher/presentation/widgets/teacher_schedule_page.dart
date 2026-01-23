import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../domain/entities/schedule_entity.dart';

class TeacherSchedulePage extends StatefulWidget {
  final TeacherDashboardController controller;

  const TeacherSchedulePage({super.key, required this.controller});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  int _selectedDayIndex = DateTime.now().weekday - 1;

  final List<String> _dayNames = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
  final List<DayOfWeek> _days = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
    DayOfWeek.saturday,
    DayOfWeek.sunday
  ];

  @override
  void initState() {
    super.initState();
    if (_selectedDayIndex > 6) _selectedDayIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1A1F26),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Orarul meu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        '${widget.controller.teacherSchedules.length} ore în total săptămâna aceasta',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      )),
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
                      Icons.calendar_today_rounded,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),


            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dayNames.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDayIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : const Color(0xFF1A1F26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayNames[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),


            Expanded(
              child: Obx(() {
                if (widget.controller.isLoadingTeacherSchedule.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                final selectedDay = _days[_selectedDayIndex];
                final daySchedule = widget.controller.teacherSchedules
                    .where((s) => s.dayOfWeek == selectedDay)
                    .toList()
                  ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

                if (daySchedule.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 80,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nu sunt ore programate pentru această zi',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => widget.controller.fetchTeacherSchedule(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daySchedule.length,
                    itemBuilder: (context, index) {
                      final schedule = daySchedule[index];
                      return _buildScheduleCard(schedule);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [

            Container(
              width: 60,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ora',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${schedule.periodNumber}',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            VerticalDivider(
              color: Colors.grey[800],
              width: 1,
              thickness: 1,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule.subjectName ?? 'Materie',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Clasa: ${schedule.className ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        if (schedule.room != null) ...[
                          const Icon(Icons.location_on_rounded, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Sala: ${schedule.room}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
