import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/student.dart';
import '../../data/model/grade_model.dart';
import '../../data/model/homework_model.dart';
import '../../data/model/attendance_model.dart';
import '../../data/model/schedule_model.dart';
import '../../data/model/notification_model.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/cache_service.dart';

class StudentDashboardController extends GetxController {

  var currentIndex = 0.obs;


  var isLoading = true.obs;
  var isLoadingGrades = false.obs;
  var isLoadingHomework = false.obs;
  var isLoadingAttendance = false.obs;
  var isLoadingSchedule = false.obs;
  var isLoadingNotifications = false.obs;


  var student = Rxn<StudentModel>();
  var grades = <GradeModel>[].obs;
  var homework = <HomeworkModel>[].obs;
  var attendance = <AttendanceModel>[].obs;
  var schedules = <ScheduleModel>[].obs;
  var notifications = <NotificationModel>[].obs;


  StudentDataApi? _api;


  final WebSocketService _ws = WebSocketService.instance;

  @override
  void onInit() {
    super.onInit();
    _initializeAndFetch();
    _initWebSocketListeners();
  }

  @override
  void onClose() {
    _ws.disconnect();
    super.onClose();
  }

  void _initWebSocketListeners() {
    _ws.connect();

    _ws.messageStream.listen((msg) async {
      if (msg.type == NotificationType.grade ||
          msg.type == NotificationType.homework ||
          msg.type == NotificationType.attendance) {
        try {
          await CacheService.clearCache('grades_cache');
          await CacheService.clearCache('notifications_cache');
          await CacheService.clearCache('homework_cache');
          await CacheService.clearCache('attendance_cache');
        } catch (_) {}

        await fetchGrades(forceRefresh: true);
        await fetchHomework(forceRefresh: true);
        await fetchAttendance(forceRefresh: true);
        await fetchNotifications(forceRefresh: true);

        final notification = msg.data['notification'];
        final title = (notification is Map && notification['title'] != null)
            ? notification['title'].toString()
            : (msg.type == NotificationType.homework
                ? 'Temă nouă'
                : msg.type == NotificationType.attendance
                    ? 'Prezență'
                    : 'Notă nouă');

        final message = (notification is Map && notification['message'] != null)
            ? notification['message'].toString()
            : (msg.type == NotificationType.homework
                ? 'Ai primit o temă nouă.'
                : msg.type == NotificationType.attendance
                    ? 'A fost înregistrată o absență/prezență.'
                    : 'Ai primit o notă nouă.');

        if (Get.isSnackbarOpen) {
          Get.closeCurrentSnackbar();
        }

        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueGrey.shade900,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }, onError: (e) {
      debugPrint('WS student listener error: $e');
    });
  }

  Future<void> _initializeAndFetch() async {
    try {
      final dio = await DioClient.getInstance();
      _api = StudentDataApi(dio);
      await fetchStudentData();
    } catch (e) {
      debugPrint('Error initializing: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStudentData({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final studentData = await _api?.getMe();
      if (studentData != null) {
        student.value = studentData;
        isLoading.value = false;
        fetchGrades(forceRefresh: forceRefresh);
        fetchSchedule(forceRefresh: forceRefresh);
        fetchHomework(forceRefresh: forceRefresh);
        fetchAttendance(forceRefresh: forceRefresh);
        fetchNotifications(forceRefresh: forceRefresh);
      }
    } catch (e) {
      debugPrint('Error fetching student data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchGrades({bool forceRefresh = false}) async {
    isLoadingGrades.value = true;
    try {
      final data = await _api?.getMyGrades(forceRefresh: forceRefresh);
      if (data != null) {
        grades.value = data;
      }
    } catch (e) {
      debugPrint('Error fetching grades: $e');
    } finally {
      isLoadingGrades.value = false;
    }
  }

  Future<void> fetchSchedule({bool forceRefresh = false}) async {
    isLoadingSchedule.value = true;
    try {
      final classId = student.value?.classId;
      if (classId != null && classId.isNotEmpty) {
        final data = await _api?.getClassSchedule(
          classId,
          forceRefresh: forceRefresh,
        );
        if (data != null) {
          schedules.value = data;
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    } finally {
      isLoadingSchedule.value = false;
    }
  }

  Future<void> fetchHomework({bool forceRefresh = false}) async {
    isLoadingHomework.value = true;
    try {
      final data = await _api?.getMyHomework(forceRefresh: forceRefresh);
      if (data != null) {
        homework.value = data;
      }
    } catch (e) {
      debugPrint('Error fetching homework: $e');
    } finally {
      isLoadingHomework.value = false;
    }
  }

  Future<void> fetchAttendance({bool forceRefresh = false}) async {
    isLoadingAttendance.value = true;
    try {
      final studentId = student.value?.userId;
      if (studentId != null && studentId.isNotEmpty) {
        final data = await _api?.getMyAttendance(
          studentId,
          forceRefresh: forceRefresh,
        );
        if (data != null) {
          attendance.value = data;
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    isLoadingNotifications.value = true;
    try {
      final data = await _api?.getMyNotifications(forceRefresh: forceRefresh);
      if (data != null) {
        notifications.value = data;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _api?.markNotificationAsRead(notificationId);
      await fetchNotifications(forceRefresh: true);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  double get averageGrade {
    if (grades.isEmpty) return 0.0;
    final total = grades.fold<int>(0, (sum, grade) => sum + grade.value);
    return total / grades.length;
  }

  double get attendancePercentage {
    if (attendance.isEmpty) return 100.0;
    final present = attendance
        .where((a) => a.status == 'present' || a.status == 'late')
        .length;
    return (present / attendance.length) * 100;
  }

  int get pendingHomeworkCount {
    return homework.length;
  }

  int get unreadNotificationsCount {
    return notifications.where((n) => !n.isRead).length;
  }


  int get unreadNotifications => unreadNotificationsCount;

  List<HomeworkModel> get urgentHomework {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return homework
        .where(
          (h) =>
              h.dueDate.isBefore(threeDaysFromNow) &&
              h.dueDate.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  ScheduleModel? get nextLesson {
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);

    final todaySchedules =
        schedules
            .where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase())
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    for (var schedule in todaySchedules) {
      final lessonTime = _parseTime(schedule.startTime);
      if (lessonTime.isAfter(now)) {
        return schedule;
      }
    }
    return null;
  }

  List<ScheduleModel> getTodaySchedule() {
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);

    return schedules
        .where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase())
        .toList()
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
  }

  List<ScheduleModel> getScheduleForDay(String day) {
    return schedules
        .where((s) => s.dayOfWeek.toLowerCase() == day.toLowerCase())
        .toList()
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
  }

  Map<String, List<GradeModel>> get gradesBySubject {
    final Map<String, List<GradeModel>> grouped = {};
    for (var grade in grades) {
      final subjectName = grade.subjectName;
      if (!grouped.containsKey(subjectName)) {
        grouped[subjectName] = [];
      }
      grouped[subjectName]!.add(grade);
    }
    return grouped;
  }

  double getSubjectAverage(String subjectName) {
    final subjectGrades = gradesBySubject[subjectName] ?? [];
    if (subjectGrades.isEmpty) return 0.0;
    final total = subjectGrades.fold<int>(0, (sum, grade) => sum + grade.value);
    return total / subjectGrades.length;
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

  String getTimeUntilLesson(ScheduleModel? lesson) {
    if (lesson == null) return '';
    final lessonTime = _parseTime(lesson.startTime);
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
}
