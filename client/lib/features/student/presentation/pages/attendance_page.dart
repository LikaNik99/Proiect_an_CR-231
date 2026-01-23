import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/student.dart';
import '../../data/model/attendance_model.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  StudentDataApi? _api;
  StudentModel? _student;
  List<AttendanceModel> _attendance = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = await DioClient.getInstance();
      _api = StudentDataApi(dio);

      _student = await _api?.getMe();
      if (_student != null && _student!.userId != null) {
        _attendance = await _api?.getMyAttendance(_student!.userId!) ?? [];
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Prezență',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.blueAccent,
              backgroundColor: const Color(0xFF1A1F26),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildStatsOverview(),
                    _buildMonthSelector(),
                    _buildCalendar(),
                    _buildLegend(),
                    _buildRecentAbsences(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    final total = _attendance.length;
    final present = _attendance.where((a) => a.status == 'present').length;
    final late = _attendance.where((a) => a.status == 'late').length;
    final absent = _attendance.where((a) => a.status == 'absent').length;
    final excused = _attendance.where((a) => a.status == 'excused').length;

    final percentage = total > 0 ? ((present + late) / total * 100) : 100.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            percentage >= 90
                ? const Color(0xFF10B981)
                : percentage >= 75
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
            percentage >= 90
                ? const Color(0xFF059669)
                : percentage >= 75
                    ? const Color(0xFFD97706)
                    : const Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata de prezență',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat('Prezent', present, Colors.white),
              _buildMiniStat('Întârziat', late, Colors.white),
              _buildMiniStat('Absent', absent, Colors.white),
              _buildMiniStat('Motivat', excused, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'ro').format(_selectedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              if (_selectedMonth.isBefore(DateTime.now())) {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday;

    final monthAttendance = _attendance.where((a) {
      return a.attendanceDate.year == _selectedMonth.year &&
          a.attendanceDate.month == _selectedMonth.month;
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (startingWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayOffset);
              final isWeekend = date.weekday == 6 || date.weekday == 7;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              final dayAttendance = monthAttendance.where((a) =>
                  a.attendanceDate.year == date.year &&
                  a.attendanceDate.month == date.month &&
                  a.attendanceDate.day == date.day);

              Color? backgroundColor;
              Color textColor = Colors.white;

              if (dayAttendance.isNotEmpty) {
                final status = dayAttendance.first.status;
                switch (status) {
                  case 'present':
                    backgroundColor = const Color(0xFF10B981);
                    break;
                  case 'late':
                    backgroundColor = const Color(0xFFF59E0B);
                    break;
                  case 'absent':
                    backgroundColor = const Color(0xFFEF4444);
                    break;
                  case 'excused':
                    backgroundColor = const Color(0xFF3B82F6);
                    break;
                }
              } else if (isWeekend) {
                textColor = Colors.grey[600]!;
              }

              return Container(
                decoration: BoxDecoration(
                  color: backgroundColor?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? Border.all(color: Colors.blueAccent, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    dayOffset.toString(),
                    style: TextStyle(
                      color: backgroundColor != null ? Colors.white : textColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Prezent', const Color(0xFF10B981)),
          _buildLegendItem('Întârziat', const Color(0xFFF59E0B)),
          _buildLegendItem('Absent', const Color(0xFFEF4444)),
          _buildLegendItem('Motivat', const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAbsences() {
    final recentAbsences = _attendance
        .where((a) => a.status == 'absent' || a.status == 'late')
        .toList()
      ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

    if (recentAbsences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Absențe recente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...recentAbsences.take(5).map((attendance) {
            final isAbsent = attendance.status == 'absent';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isAbsent ? Icons.close : Icons.schedule,
                      color: isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.subjectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMMM yyyy', 'ro')
                              .format(attendance.attendanceDate),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAbsent ? 'Absent' : 'Întârziat',
                      style: TextStyle(
                        color: isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
