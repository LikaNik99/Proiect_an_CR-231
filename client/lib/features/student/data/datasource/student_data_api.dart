import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/cache_service.dart';
import '../model/grade_model.dart';
import '../model/schedule_model.dart';
import '../model/homework_model.dart';
import '../model/attendance_model.dart';
import '../model/notification_model.dart';
import '../model/material_model.dart';
import '../model/student.dart';

class StudentDataApi {
  final Dio dio;

  StudentDataApi(this.dio);



  Future<StudentModel?> getMe() async {
    try {
      final response = await dio.get('/students/me');
      if (response.statusCode == 200) {
        await CacheService.cacheStudent(
          Map<String, dynamic>.from(response.data),
        );
        return StudentModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching current student: $e');

      final cached = CacheService.getCachedStudent();
      if (cached != null) {
        return StudentModel.fromJson(cached);
      }
      return null;
    }
  }



  Future<List<GradeModel>> getMyGrades({bool forceRefresh = false}) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedGrades();
      if (cached != null && !CacheService.isCacheStale('grades_cache')) {
        debugPrint('>>> Using cached grades');
        return cached.map((json) => GradeModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/grades/my-grades');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheGrades(
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => GradeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching grades: $e');

      final cached = CacheService.getCachedGrades();
      if (cached != null) {
        return cached.map((json) => GradeModel.fromJson(json)).toList();
      }
      return [];
    }
  }



  Future<List<ScheduleModel>> getClassSchedule(
    String classId, {
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedSchedule(classId);
      if (cached != null &&
          !CacheService.isCacheStale('schedule_cache:$classId')) {
        debugPrint('>>> Using cached schedule');
        return cached.map((json) => ScheduleModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/schedules/class/$classId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheSchedule(
          classId,
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching schedule: $e');

      final cached = CacheService.getCachedSchedule(classId);
      if (cached != null) {
        return cached.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    }
  }



  /// Returns homework visible to the current student (class + personal).
  Future<List<HomeworkModel>> getMyHomework({bool forceRefresh = false}) async {
    const myKey = '__my__';

    if (!forceRefresh) {
      final cached = CacheService.getCachedHomework(myKey);
      if (cached != null && !CacheService.isCacheStale('homework_cache:$myKey')) {
        debugPrint('>>> Using cached my-homework');
        return cached.map((json) => HomeworkModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/homework/my');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        await CacheService.cacheHomework(
          myKey,
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => HomeworkModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my homework: $e');
      final cached = CacheService.getCachedHomework(myKey);
      if (cached != null) {
        return cached.map((json) => HomeworkModel.fromJson(json)).toList();
      }
      return [];
    }
  }

  Future<List<HomeworkModel>> getClassHomework(
    String classId, {
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedHomework(classId);
      if (cached != null &&
          !CacheService.isCacheStale('homework_cache:$classId')) {
        debugPrint('>>> Using cached homework');
        return cached.map((json) => HomeworkModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/homework/class/$classId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheHomework(
          classId,
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => HomeworkModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching homework: $e');

      final cached = CacheService.getCachedHomework(classId);
      if (cached != null) {
        return cached.map((json) => HomeworkModel.fromJson(json)).toList();
      }
      return [];
    }
  }



  Future<List<AttendanceModel>> getMyAttendance(
    String studentId, {
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedAttendance(studentId);
      if (cached != null &&
          !CacheService.isCacheStale('attendance_cache:$studentId')) {
        debugPrint('>>> Using cached attendance');
        return cached.map((json) => AttendanceModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/attendance/student/$studentId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheAttendance(
          studentId,
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => AttendanceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching attendance: $e');

      final cached = CacheService.getCachedAttendance(studentId);
      if (cached != null) {
        return cached.map((json) => AttendanceModel.fromJson(json)).toList();
      }
      return [];
    }
  }



  Future<List<NotificationModel>> getMyNotifications({
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedNotifications();
      if (cached != null &&
          !CacheService.isCacheStale(
            'notifications_cache',
            maxAge: Duration(minutes: 5),
          )) {
        debugPrint('>>> Using cached notifications');
        return cached.map((json) => NotificationModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/notifications/my-notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheNotifications(
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');

      final cached = CacheService.getCachedNotifications();
      if (cached != null) {
        return cached.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await dio.put('/notifications/$notificationId/read');

      await CacheService.clearCache('notifications_cache');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }



  Future<List<MaterialModel>> getClassMaterials(
    String classId, {
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh) {
      final cached = CacheService.getCachedMaterials(classId);
      if (cached != null &&
          !CacheService.isCacheStale('materials_cache:$classId')) {
        debugPrint('>>> Using cached materials');
        return cached.map((json) => MaterialModel.fromJson(json)).toList();
      }
    }

    try {
      final response = await dio.get('/materials/class/$classId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        await CacheService.cacheMaterials(
          classId,
          data.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        return data.map((json) => MaterialModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching materials: $e');

      final cached = CacheService.getCachedMaterials(classId);
      if (cached != null) {
        return cached.map((json) => MaterialModel.fromJson(json)).toList();
      }
      return [];
    }
  }



  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/password/change',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Parola a fost schimbată cu succes',
        };
      }
      return {
        'success': false,
        'message': response.data['detail'] ?? 'Eroare la schimbarea parolei',
      };
    } on DioException catch (e) {
      debugPrint('Error changing password: $e');
      String message = 'Eroare la schimbarea parolei';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        }
      }
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {'success': false, 'message': 'Eroare la schimbarea parolei'};
    }
  }
}
