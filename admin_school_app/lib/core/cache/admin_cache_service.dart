import 'package:hive/hive.dart';

/// Local cache for admin data
class AdminCacheService {
  static final AdminCacheService _instance = AdminCacheService._internal();
  factory AdminCacheService() => _instance;
  AdminCacheService._internal();


  static const String _schoolsBox = 'admin_schools';
  static const String _teachersBox = 'admin_teachers';
  static const String _studentsBox = 'admin_students';
  static const String _classesBox = 'admin_classes';
  static const String _subjectsBox = 'admin_subjects';

  /// Initialize all cache boxes
  Future<void> initialize() async {
    await Future.wait([
      _openBox(_schoolsBox),
      _openBox(_teachersBox),
      _openBox(_studentsBox),
      _openBox(_classesBox),
      _openBox(_subjectsBox),
    ]);
  }

  Future<void> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }



  /// Cache schools
  Future<void> cacheSchools(List<Map<String, dynamic>> schools) async {
    final box = await Hive.openBox<Map>(_schoolsBox);
    await box.clear();
    for (var school in schools) {
      await box.put(school['id'], school);
    }
  }

  /// Get cached schools
  List<Map<String, dynamic>> getCachedSchools() {
    if (!Hive.isBoxOpen(_schoolsBox)) return [];
    final box = Hive.box<Map>(_schoolsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Cache single school
  Future<void> cacheSchool(Map<String, dynamic> school) async {
    final box = await Hive.openBox<Map>(_schoolsBox);
    await box.put(school['id'], school);
  }

  /// Get cached school by ID
  Map<String, dynamic>? getCachedSchool(String id) {
    if (!Hive.isBoxOpen(_schoolsBox)) return null;
    final box = Hive.box<Map>(_schoolsBox);
    final data = box.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Remove cached school
  Future<void> removeCachedSchool(String id) async {
    final box = await Hive.openBox<Map>(_schoolsBox);
    await box.delete(id);
  }



  /// Cache teachers
  Future<void> cacheTeachers(List<Map<String, dynamic>> teachers) async {
    final box = await Hive.openBox<Map>(_teachersBox);
    await box.clear();
    for (var teacher in teachers) {
      await box.put(teacher['id'], teacher);
    }
  }

  /// Get cached teachers
  List<Map<String, dynamic>> getCachedTeachers() {
    if (!Hive.isBoxOpen(_teachersBox)) return [];
    final box = Hive.box<Map>(_teachersBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Cache single teacher
  Future<void> cacheTeacher(Map<String, dynamic> teacher) async {
    final box = await Hive.openBox<Map>(_teachersBox);
    await box.put(teacher['id'], teacher);
  }

  /// Get cached teacher by ID
  Map<String, dynamic>? getCachedTeacher(String id) {
    if (!Hive.isBoxOpen(_teachersBox)) return null;
    final box = Hive.box<Map>(_teachersBox);
    final data = box.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Remove cached teacher
  Future<void> removeCachedTeacher(String id) async {
    final box = await Hive.openBox<Map>(_teachersBox);
    await box.delete(id);
  }



  /// Cache students
  Future<void> cacheStudents(List<Map<String, dynamic>> students) async {
    final box = await Hive.openBox<Map>(_studentsBox);
    await box.clear();
    for (var student in students) {
      await box.put(student['id'], student);
    }
  }

  /// Get cached students
  List<Map<String, dynamic>> getCachedStudents() {
    if (!Hive.isBoxOpen(_studentsBox)) return [];
    final box = Hive.box<Map>(_studentsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Cache single student
  Future<void> cacheStudent(Map<String, dynamic> student) async {
    final box = await Hive.openBox<Map>(_studentsBox);
    await box.put(student['id'], student);
  }

  /// Get cached student by ID
  Map<String, dynamic>? getCachedStudent(String id) {
    if (!Hive.isBoxOpen(_studentsBox)) return null;
    final box = Hive.box<Map>(_studentsBox);
    final data = box.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Remove cached student
  Future<void> removeCachedStudent(String id) async {
    final box = await Hive.openBox<Map>(_studentsBox);
    await box.delete(id);
  }



  /// Clear all caches
  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<Map>(_schoolsBox).clear(),
      Hive.box<Map>(_teachersBox).clear(),
      Hive.box<Map>(_studentsBox).clear(),
    ]);
  }

  /// Get cache stats
  Map<String, int> getCacheStats() {
    return {
      'schools': getCachedSchools().length,
      'teachers': getCachedTeachers().length,
      'students': getCachedStudents().length,
    };
  }
}
