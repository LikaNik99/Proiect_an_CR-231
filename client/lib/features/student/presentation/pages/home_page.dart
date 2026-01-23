import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/schedule_model.dart';
import '../widgets/buildSmallCard.dart';
import 'homework_page.dart';
import 'notes_page.dart';
import 'schedule_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StudentDataApi? _api;
  ScheduleModel? _nextLesson;
  bool _isLoadingSchedule = true;
  String _nextLessonTime = '';

  final List<Map<String, dynamic>> cards = const [
    {
      "titleKey": "homework_card",
      "icon": Icons.assignment,
      "color": Color(0xFF10B981),
      "page": HomeworkPage(),
    },
    {
      "titleKey": "notes_card",
      "icon": Icons.school,
      "color": Color(0xFFA855F7),
      "page": NotesPage(),
    },
    {
      "titleKey": "schedule_card",
      "icon": Icons.calendar_today,
      "color": Color(0xFF3B82F6),
      "page": SchedulePage(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadNextLesson();
  }

  Future<void> _loadNextLesson() async {
    setState(() => _isLoadingSchedule = true);

    try {
      if (_api == null) {
        final dio = await DioClient.getInstance();
        _api = StudentDataApi(dio);
      }

      final student = await _api!.getMe();
      if (student != null && student.classId.isNotEmpty) {
        final schedules = await _api!.getClassSchedule(student.classId!);

        final now = DateTime.now();
        final currentDay = _getDayName(now.weekday);

        final todaySchedules =
            schedules
                .where(
                  (s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase(),
                )
                .toList()
              ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

        if (todaySchedules.isNotEmpty) {
          for (var schedule in todaySchedules) {
            final lessonTime = _parseTime(schedule.startTime);
            if (lessonTime.isAfter(now)) {
              setState(() {
                _nextLesson = schedule;
                _nextLessonTime = _calculateTimeUntil(lessonTime);
                _isLoadingSchedule = false;
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading next lesson: $e');
    }

    setState(() => _isLoadingSchedule = false);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _calculateTimeUntil(DateTime lessonTime) {
    final now = DateTime.now();
    final difference = lessonTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inDays}d';
    }
  }

  Future<void> _handleRefresh() async {
    await _loadNextLesson();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0D),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF111827)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'home'.tr,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () => Get.to(() => const SchedulePage()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.03),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isLoadingSchedule
                        ? const Center(
                            child: SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nextLesson != null
                                          ? 'next_lesson_title'.tr
                                          : 'Nu există ore astăzi',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _nextLesson != null
                                          ? '${_nextLesson!.subjectName} - ${_nextLesson!.startTime}'
                                          : 'Relaxează-te!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_nextLesson != null) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _nextLessonTime.isNotEmpty
                                                  ? 'În $_nextLessonTime'
                                                  : 'În curând',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          if (_nextLesson!.room != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Sala ${_nextLesson!.room}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                Column(
                  children: List.generate(cards.length, (index) {
                    final card = cards[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: buildSmallCard(context, card),
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
