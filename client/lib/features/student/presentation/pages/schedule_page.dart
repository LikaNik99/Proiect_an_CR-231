import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/schedule_model.dart';
import '../../data/model/homework_model.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  StudentDataApi? _api;
  List<ScheduleModel> _schedules = [];
  List<HomeworkModel> _homework = [];
  bool _isLoading = true;
  int _selectedDay = DateTime.now().weekday - 1;

  final List<String> _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final List<String> _dayNames = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    if (_api == null) {
      final dio = await DioClient.getInstance();
      _api = StudentDataApi(dio);
    }

    final student = await _api!.getMe();
    if (student == null || student.classId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final schedules = await _api!.getClassSchedule(student.classId);
    final homework = await _api!.getClassHomework(student.classId);
    setState(() {
      _schedules = schedules;
      _homework = homework;
      _isLoading = false;
    });
  }

  List<ScheduleModel> _getScheduleForDay(String day) {
    return _schedules.where((s) => s.dayOfWeek == day).toList()
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dayKey = _days[_selectedDay];
    final daySchedule = _getScheduleForDay(dayKey);

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final selectedDate = DateTime(monday.year, monday.month, monday.day).add(Duration(days: _selectedDay));

    final dayHomework = _homework.where((h) => _sameDay(h.dueDate, selectedDate)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: Text('schedule_page_title'.tr),
        backgroundColor: const Color(0xFF0F172A),
      ),
      backgroundColor: const Color(0xFF0B0B0D),
      body: Column(
        children: [
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: _dayNames.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Color(0xFF1A1C20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[index],
                        style: TextStyle(
                          color: Colors.white,
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSchedule,
                    child: daySchedule.isEmpty && dayHomework.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, size: 64, color: Colors.white24),
                                SizedBox(height: 16),
                                Text('Nu există ore/teme pentru această zi',
                                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.all(16),
                            children: [

                              ...daySchedule.map((schedule) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF1A1C20), Color(0xFF111827)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          schedule.periodNumber.toString(),
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      schedule.subjectName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          '${schedule.startTime} - ${schedule.endTime}',
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),


                              if (dayHomework.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Teme pentru acasă',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                ...dayHomework.map((hw) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.assignment, color: Colors.orange, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(hw.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 4),
                                              Text(hw.title, style: TextStyle(color: Colors.grey[300])),
                                              if ((hw.description ?? '').isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(hw.description!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                              ]
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
