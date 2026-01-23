import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Local caching service using Hive
/// Provides offline-first data access with automatic cache invalidation
class CacheService {
  static const String _gradesBox = 'grades_cache';
  static const String _scheduleBox = 'schedule_cache';
  static const String _homeworkBox = 'homework_cache';
  static const String _notificationsBox = 'notifications_cache';
  static const String _attendanceBox = 'attendance_cache';
  static const String _studentBox = 'student_cache';
  static const String _materialsBox = 'materials_cache';
  static const String _metadataBox = 'cache_metadata';
  static const String _userBox = 'user_cache';

  static bool _initialized = false;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<dynamic>(_gradesBox),
      Hive.openBox<dynamic>(_scheduleBox),
      Hive.openBox<dynamic>(_homeworkBox),
      Hive.openBox<dynamic>(_notificationsBox),
      Hive.openBox<dynamic>(_attendanceBox),
      Hive.openBox<dynamic>(_studentBox),
      Hive.openBox<dynamic>(_materialsBox),
      Hive.openBox<dynamic>(_metadataBox),
      Hive.openBox<dynamic>(_userBox),
    ]);

    _initialized = true;
    debugPrint('CacheService initialized');
  }



  static Future<void> cacheGrades(List<Map<String, dynamic>> grades) async {
    final box = Hive.box<dynamic>(_gradesBox);
    await box.clear();
    await box.put('data', grades);
    await _updateTimestamp(_gradesBox);
  }

  static List<Map<String, dynamic>>? getCachedGrades() {
    final box = Hive.box<dynamic>(_gradesBox);
    final data = box.get('data');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheSchedule(
      String classId, List<Map<String, dynamic>> schedule) async {
    final box = Hive.box<dynamic>(_scheduleBox);
    await box.put(classId, schedule);
    await _updateTimestamp('$_scheduleBox:$classId');
  }

  static List<Map<String, dynamic>>? getCachedSchedule(String classId) {
    final box = Hive.box<dynamic>(_scheduleBox);
    final data = box.get(classId);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheHomework(
      String classId, List<Map<String, dynamic>> homework) async {
    final box = Hive.box<dynamic>(_homeworkBox);
    await box.put(classId, homework);
    await _updateTimestamp('$_homeworkBox:$classId');
  }

  static List<Map<String, dynamic>>? getCachedHomework(String classId) {
    final box = Hive.box<dynamic>(_homeworkBox);
    final data = box.get(classId);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheNotifications(
      List<Map<String, dynamic>> notifications) async {
    final box = Hive.box<dynamic>(_notificationsBox);
    await box.clear();
    await box.put('data', notifications);
    await _updateTimestamp(_notificationsBox);
  }

  static List<Map<String, dynamic>>? getCachedNotifications() {
    final box = Hive.box<dynamic>(_notificationsBox);
    final data = box.get('data');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheAttendance(
      String studentId, List<Map<String, dynamic>> attendance) async {
    final box = Hive.box<dynamic>(_attendanceBox);
    await box.put(studentId, attendance);
    await _updateTimestamp('$_attendanceBox:$studentId');
  }

  static List<Map<String, dynamic>>? getCachedAttendance(String studentId) {
    final box = Hive.box<dynamic>(_attendanceBox);
    final data = box.get(studentId);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheMaterials(
      String classId, List<Map<String, dynamic>> materials) async {
    final box = Hive.box<dynamic>(_materialsBox);
    await box.put(classId, materials);
    await _updateTimestamp('$_materialsBox:$classId');
  }

  static List<Map<String, dynamic>>? getCachedMaterials(String classId) {
    final box = Hive.box<dynamic>(_materialsBox);
    final data = box.get(classId);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  static Future<void> cacheStudent(Map<String, dynamic> student) async {
    final box = Hive.box<dynamic>(_studentBox);
    await box.put('current', student);
    await _updateTimestamp(_studentBox);
  }

  static Map<String, dynamic>? getCachedStudent() {
    final box = Hive.box<dynamic>(_studentBox);
    final data = box.get('current');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }



  static Future<void> cacheUser(Map<String, dynamic> user) async {
    final box = Hive.box<dynamic>(_userBox);
    await box.put('current_user', user);
    await _updateTimestamp(_userBox);
    debugPrint('✅ User cached: ${user['username']}');
  }

  static Map<String, dynamic>? getCachedUser() {
    if (!Hive.isBoxOpen(_userBox)) return null;
    final box = Hive.box<dynamic>(_userBox);
    final data = box.get('current_user');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  static Future<void> clearUserCache() async {
    final box = Hive.box<dynamic>(_userBox);
    await box.clear();
    debugPrint('🗑️ User cache cleared');
  }



  /// Check if cache is stale (older than maxAge)
  static bool isCacheStale(String key, {Duration maxAge = const Duration(minutes: 15)}) {
    final metaBox = Hive.box<dynamic>(_metadataBox);
    final timestamp = metaBox.get('timestamp:$key');
    if (timestamp == null) return true;

    final cachedTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cachedTime) > maxAge;
  }

  /// Update cache timestamp
  static Future<void> _updateTimestamp(String key) async {
    final metaBox = Hive.box<dynamic>(_metadataBox);
    await metaBox.put('timestamp:$key', DateTime.now().toIso8601String());
  }

  /// Get last update time for a cache
  static DateTime? getLastUpdate(String key) {
    final metaBox = Hive.box<dynamic>(_metadataBox);
    final timestamp = metaBox.get('timestamp:$key');
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  /// Clear all cached data
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box<dynamic>(_gradesBox).clear(),
      Hive.box<dynamic>(_scheduleBox).clear(),
      Hive.box<dynamic>(_homeworkBox).clear(),
      Hive.box<dynamic>(_notificationsBox).clear(),
      Hive.box<dynamic>(_attendanceBox).clear(),
      Hive.box<dynamic>(_studentBox).clear(),
      Hive.box<dynamic>(_materialsBox).clear(),
      Hive.box<dynamic>(_metadataBox).clear(),
      Hive.box<dynamic>(_userBox).clear(),
    ]);
    debugPrint('All cache cleared');
  }

  /// Clear specific cache
  static Future<void> clearCache(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).clear();
    }
  }

  /// Close all boxes (for cleanup)
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
