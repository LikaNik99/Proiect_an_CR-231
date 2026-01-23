import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/datasource/teacher_remote_data_source.dart';
import '../../data/datasource/grade_remote_data_source.dart';
import '../../data/datasource/homework_remote_data_source.dart';
import '../../data/datasource/attendance_remote_data_source.dart';
import '../../data/datasource/schedule_remote_data_source.dart';
import '../../data/datasource/material_remote_data_source.dart';
import '../../data/model/teacher_model.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/entities/grade_entity.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/entities/material_entity.dart';
import '../../../student/data/model/student.dart';
import '../../domain/usecases/get_current_teacher.dart';
import '../../../../core/offline/offline_action_handler.dart';
import '../../../../core/sync/sync_operation.dart';

class TeacherDashboardController extends GetxController {

  final GetCurrentTeacherUseCase getCurrentTeacherUseCase = GetIt.instance
      .get<GetCurrentTeacherUseCase>();
  final GradeRemoteDataSource gradeDataSource = GetIt.instance
      .get<GradeRemoteDataSource>();
  final HomeworkRemoteDataSource homeworkDataSource = GetIt.instance
      .get<HomeworkRemoteDataSource>();
  final AttendanceRemoteDataSource attendanceDataSource = GetIt.instance
      .get<AttendanceRemoteDataSource>();
  final ScheduleRemoteDataSource scheduleDataSource = GetIt.instance
      .get<ScheduleRemoteDataSource>();
  final MaterialRemoteDataSource materialDataSource = GetIt.instance
      .get<MaterialRemoteDataSource>();


  final teacher = Rxn<Teacher>();
  final classes = <SchoolClass>[].obs;
  final allStudents = <StudentModel>[].obs;
  final allTeachers = <TeacherModel>[].obs;
  final isLoadingTeachers = false.obs;


  final grades = <Grade>[].obs;
  final isLoadingGrades = false.obs;


  final homeworkList = <Homework>[].obs;
  final isLoadingHomework = false.obs;


  final attendanceList = <Attendance>[].obs;
  final isLoadingAttendance = false.obs;


  final schedules = <Schedule>[].obs;
  final isLoadingSchedule = false.obs;


  final materials = <Material>[].obs;
  final isLoadingMaterials = false.obs;


  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final currentIndex = 0.obs;

  final OfflineActionHandler offlineHandler = GetIt.instance.get<
      OfflineActionHandler>();

  @override
  void onInit() {
    super.onInit();
    fetchCurrentTeacher();
  }


  Future<void> fetchCurrentTeacher() async {
    isLoading.value = true;
    try {
      print('👨‍🏫 [TeacherDashboard] fetchCurrentTeacher() start');
      final token = await SecureStorageService.getToken();
      print('👨‍🏫 [TeacherDashboard] tokenPresent=${token != null}');
      if (token == null) {
        errorMessage.value = 'No token available';
        _redirectToLogin();
        return;
      }

      final fetchedTeacher = await getCurrentTeacherUseCase.call(token);
      print('👨‍🏫 [TeacherDashboard] fetchedTeacher id=${fetchedTeacher.id} username=${fetchedTeacher.username}');
      teacher.value = fetchedTeacher;


      try {
        final ds = GetIt.instance.get<TeacherRemoteDataSource>();
        final teaching = await ds.getMyTeachingClasses(token);
        print('👨‍🏫 [TeacherDashboard] teachingClassesCount=${teaching.length}');
        classes.value = teaching;
      } catch (e) {

        print('👨‍🏫 [TeacherDashboard] getMyTeachingClasses failed, fallback to /teachers/me classes. error=$e');
        classes.value = fetchedTeacher.classes ?? [];
      }

      print('👨‍🏫 [TeacherDashboard] classesCount=${classes.length}');


      for (final c in classes) {
        print('📚 [TeacherDashboard] class=${c.id} name=${c.name} subjectsFromAPI=${c.subjects.length}');
        final subs = c.subjects
            .where((s) => s.id.isNotEmpty)
            .map((s) => {'id': s.id, 'name': s.name})
            .toList();
        if (subs.isNotEmpty) {
          subjectsByClassId[c.id] = subs;
          if (subs.length == 1 && (selectedSubjectByClassId[c.id]?['id'] ?? '').isEmpty) {
            selectedSubjectByClassId[c.id] = subs.first;
          }
        }
      }


      final students = <StudentModel>[];
      for (var schoolClass in classes) {
        students.addAll(schoolClass.students);
      }
      allStudents.value = students;
      print('👨‍🏫 [TeacherDashboard] allStudentsCount=${allStudents.length}');


      if (teacher.value != null) {
        print('👨‍🏫 [TeacherDashboard] fetching grades + schedule...');
        await Future.wait([fetchTeacherGrades(), fetchTeacherSchedule()]);
        print('👨‍🏫 [TeacherDashboard] after fetchTeacherSchedule: teacherSchedules=${teacherSchedules.length} schedules=${schedules.length}');
      }
      print('👨‍🏫 [TeacherDashboard] fetchCurrentTeacher() done');
    } on DioException catch (e) {
      errorMessage.value = 'Error fetching teacher: $e';
      print('👨‍🏫 [TeacherDashboard] Error fetching teacher: $e');


      if (e.response?.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (e) {
      errorMessage.value = 'Error fetching teacher: $e';
      print('👨‍🏫 [TeacherDashboard] Error fetching teacher: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _redirectToLogin() async {
    await SecureStorageService.deleteToken();
    Get.snackbar(
      'Sesiune expirată',
      'Te rugăm să te autentifici din nou',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    Get.offAll(() => const LoginPage());
  }


  Future<void> fetchTeacherGrades() async {
    if (teacher.value == null) return;

    isLoadingGrades.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedGrades = await gradeDataSource.getTeacherGrades(
        teacher.value!.id,
        token,
      );
      grades.value = fetchedGrades;
    } catch (e) {
      print('Error fetching grades: $e');
    } finally {
      isLoadingGrades.value = false;
    }
  }

  Future<void> fetchStudentGrades(String studentId) async {
    isLoadingGrades.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedGrades = await gradeDataSource.getStudentGrades(
        studentId,
        token,
      );
      grades.value = fetchedGrades;
    } catch (e) {
      print('Error fetching student grades: $e');
    } finally {
      isLoadingGrades.value = false;
    }
  }

  Future<void> createGrade(Map<String, dynamic> gradeData) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;


      if ((gradeData['teacher_id'] == null ||
          gradeData['teacher_id']
              .toString()
              .isEmpty) &&
          teacher.value != null) {
        gradeData['teacher_id'] = teacher.value!.id;
      }

      await gradeDataSource.createGrade(gradeData, token);
      await fetchTeacherGrades();
      Get.snackbar(
        'Succes',
        'Nota a fost adăugată cu succes!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la adăugarea notei: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateGrade(String gradeId,
      Map<String, dynamic> gradeData,) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await gradeDataSource.updateGrade(gradeId, gradeData, token);
      await fetchTeacherGrades();
      Get.snackbar(
        'Succes',
        'Nota a fost actualizată!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la actualizarea notei: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteGrade(String gradeId) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await gradeDataSource.deleteGrade(gradeId, token);
      await fetchTeacherGrades();
      Get.snackbar(
        'Succes',
        'Nota a fost ștearsă!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la ștergerea notei: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  Future<void> fetchClassHomework(String classId) async {
    isLoadingHomework.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedHomework = await homeworkDataSource.getClassHomework(
        classId,
        token,
      );
      homeworkList.value = fetchedHomework;
    } catch (e) {
      print('Error fetching homework: $e');
    } finally {
      isLoadingHomework.value = false;
    }
  }

  Future<void> createHomework(Map<String, dynamic> homeworkData) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      if ((homeworkData['teacher_id'] == null ||
          homeworkData['teacher_id']
              .toString()
              .isEmpty) &&
          teacher.value != null) {
        homeworkData['teacher_id'] = teacher.value!.id;
      }

      final res = await offlineHandler.run(
        opType: OperationType.create,
        entity: 'homework',
        payload: Map<String, dynamic>.from(homeworkData),
        remoteCall: () =>
            homeworkDataSource.createHomework(homeworkData, token),
      );

      if (res != null) {
        Get.snackbar('Succes', 'Tema a fost creată cu succes!',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Offline',
            'Tema a fost salvată local și va fi trimisă când revine serverul.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la crearea temei: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateHomework(String homeworkId,
      Map<String, dynamic> homeworkData,) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await homeworkDataSource.updateHomework(homeworkId, homeworkData, token);
      Get.snackbar(
        'Succes',
        'Tema a fost actualizată!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la actualizarea temei: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteHomework(String homeworkId) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await homeworkDataSource.deleteHomework(homeworkId, token);
      Get.snackbar(
        'Succes',
        'Tema a fost ștearsă!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la ștergerea temei: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  Future<void> fetchStudentAttendance(String studentId) async {
    isLoadingAttendance.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedAttendance = await attendanceDataSource.getStudentAttendance(
        studentId,
        token,
      );
      attendanceList.value = fetchedAttendance;
    } catch (e) {
      print('Error fetching attendance: $e');
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  Future<void> createAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;


      if ((attendanceData['teacher_id'] == null ||
          attendanceData['teacher_id']
              .toString()
              .isEmpty) &&
          teacher.value != null) {
        attendanceData['teacher_id'] = teacher.value!.id;
      }


      if (attendanceData['attendance_date'] is DateTime) {
        final dt = attendanceData['attendance_date'] as DateTime;
        attendanceData['attendance_date'] = dt.toIso8601String().split('T')[0];
      } else if (attendanceData['attendance_date'] is String) {

        final dateStr = attendanceData['attendance_date'] as String;
        if (dateStr.contains('T')) {
          attendanceData['attendance_date'] = dateStr.split('T')[0];
        }
      }

      final res = await offlineHandler.run(
        opType: OperationType.create,
        entity: 'attendance',
        payload: Map<String, dynamic>.from(attendanceData),
        remoteCall: () =>
            attendanceDataSource.createAttendance(attendanceData, token),
      );

      if (res != null) {
        Get.snackbar('Succes', 'Prezența a fost înregistrată!',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Offline',
            'Prezența a fost salvată local și va fi sincronizată automat.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Eroare', 'Eroare la înregistrarea prezenței: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateAttendance(String attendanceId,
      Map<String, dynamic> attendanceData,) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await attendanceDataSource.updateAttendance(
        attendanceId,
        attendanceData,
        token,
      );
      Get.snackbar(
        'Succes',
        'Prezența a fost actualizată!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la actualizarea prezenței: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  Future<void> fetchClassSchedule(String classId) async {
    if (classId.isEmpty) return;

    isLoadingSchedule.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedSchedules = await scheduleDataSource.getClassSchedule(
        classId,
        token,
      );
      schedules.value = fetchedSchedules;
    } catch (e) {
      print('Error fetching schedule: $e');
    } finally {
      isLoadingSchedule.value = false;
    }
  }

  Future<void> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      await scheduleDataSource.createSchedule(scheduleData, token);
      Get.snackbar(
        'Succes',
        'Orarul a fost creat!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la crearea orarului: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  Future<void> fetchTeacherMaterials() async {
    if (teacher.value == null) return;

    isLoadingMaterials.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final fetchedMaterials = await materialDataSource.getTeacherMaterials(
        teacher.value!.id,
        token,
      );
      materials.value = fetchedMaterials;
    } catch (e) {
      print('Error fetching materials: $e');
    } finally {
      isLoadingMaterials.value = false;
    }
  }


  Future<void> uploadAvatar(String filePath) async {
    if (teacher.value == null) return;
    final token = await SecureStorageService.getToken();
    if (token == null) return;

    try {
      final dio = await DioClient.getInstance();
      final remote = TeacherRemoteDataSourceImpl(dio: dio);
      final avatarUrl = await remote.uploadAvatar(
        teacher.value!.id,
        token,
        filePath,
      );

      final updated = TeacherModel.fromJson({
        'user_id': teacher.value!.id,
        'user': {
          'username': teacher.value!.username,
          'email': teacher.value!.email,
          'avatar_url': avatarUrl,
        },
        'subject': teacher.value!.subject,
        'is_homeroom': teacher.value!.isHomeroom,
        'is_director': teacher.value!.isDirector,
        'classes':
        teacher.value!.classes?.map((c) => c.toJson()).toList() ?? [],
      });
      teacher.value = updated;
      Get.snackbar(
        'Succes',
        'Avatar actualizat cu succes!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Eroare',
        'Eroare la încărcarea avatarului: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  /// Cache: classId -> list of subjects taught by this teacher in that class.
  final subjectsByClassId = <String, List<Map<String, String>>>{}.obs;

  /// Cache: classId -> selected subject {id,name} (used by catalog actions).
  final selectedSubjectByClassId = <String, Map<String, String>>{}.obs;

  /// Convenience list for UI that expects `teacherSchedules`.
  final teacherSchedules = <Schedule>[].obs;

  Future<void> fetchTeacherSchedule() async {
    if (teacher.value == null) {
      print('🗓️ [TeacherDashboard] fetchTeacherSchedule() skipped (teacher=null)');
      return;
    }
    isLoadingSchedule.value = true;
    try {
      final token = await SecureStorageService.getToken();
      print('🗓️ [TeacherDashboard] fetchTeacherSchedule() teacherId=${teacher.value!.id} tokenPresent=${token != null}');
      if (token == null) return;

      final fetched = await scheduleDataSource.getTeacherSchedule(teacher.value!.id, token);
      print('🗓️ [TeacherDashboard] fetchTeacherSchedule() fetchedCount=${fetched.length}');

      schedules.value = fetched;
      teacherSchedules.value = fetched;
    } catch (e, st) {
      print('🗓️ [TeacherDashboard] Error fetching teacher schedule: $e');
      print('🗓️ [TeacherDashboard] Stack: $st');
    } finally {
      isLoadingSchedule.value = false;
    }
  }


  int get totalClasses => classes.length;

  int get totalStudents {
    final ids = <String>{};
    for (final c in classes) {
      for (final s in c.students) {
        final id = (s.userId ?? '').toString();
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return ids.length;
  }

  int get totalGrades => grades.length;

  int get gradesThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return grades.where((g) => g.createdAt.isAfter(startOfWeek)).length;
  }

  int get absencesToday {
    final today = DateTime.now();
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    return attendanceList.where((a) => a.status.toString().toLowerCase().contains('absent') && sameDay(a.attendanceDate, today)).length;
  }

  int get lessonsToday => todaySchedule.length;


  DayOfWeek getTodayEnum() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return DayOfWeek.monday;
      case DateTime.tuesday:
        return DayOfWeek.tuesday;
      case DateTime.wednesday:
        return DayOfWeek.wednesday;
      case DateTime.thursday:
        return DayOfWeek.thursday;
      case DateTime.friday:
        return DayOfWeek.friday;
      case DateTime.saturday:
        return DayOfWeek.saturday;
      default:
        return DayOfWeek.sunday;
    }
  }

  String getDayNameRomanian(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Luni';
      case DayOfWeek.tuesday:
        return 'Marți';
      case DayOfWeek.wednesday:
        return 'Miercuri';
      case DayOfWeek.thursday:
        return 'Joi';
      case DayOfWeek.friday:
        return 'Vineri';
      case DayOfWeek.saturday:
        return 'Sâmbătă';
      case DayOfWeek.sunday:
        return 'Duminică';
    }
  }

  List<Schedule> get todaySchedule {
    final today = getTodayEnum();
    final list = List<Schedule>.from(teacherSchedules.where((s) => s.dayOfWeek == today));
    list.sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
    return list;
  }

  Schedule? get currentLesson {
    final now = TimeOfDay.now();
    DateTime parseToday(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts.first) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final d = DateTime.now();
      return DateTime(d.year, d.month, d.day, h, m);
    }

    for (final s in todaySchedule) {
      final start = parseToday(s.startTime);
      final end = parseToday(s.endTime);
      final cur = parseToday('${now.hour}:${now.minute}');
      if (cur.isAfter(start) && cur.isBefore(end)) return s;
    }
    return null;
  }

  Schedule? get nextLesson {
    final now = TimeOfDay.now();
    DateTime parseToday(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts.first) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final d = DateTime.now();
      return DateTime(d.year, d.month, d.day, h, m);
    }

    final cur = parseToday('${now.hour}:${now.minute}');
    for (final s in todaySchedule) {
      final start = parseToday(s.startTime);
      if (start.isAfter(cur)) return s;
    }
    return null;
  }

  String getTimeUntilLesson(Schedule lesson) {
    DateTime parseToday(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts.first) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final d = DateTime.now();
      return DateTime(d.year, d.month, d.day, h, m);
    }

    final start = parseToday(lesson.startTime);
    final now = DateTime.now();
    final diff = start.difference(now);
    if (diff.isNegative) return 'În desfășurare';
    final mins = diff.inMinutes;
    if (mins < 60) return '${mins}m';
    return '${diff.inHours}h ${mins % 60}m';
  }

  String getClassName(String classId) {
    final cls = classes.firstWhereOrNull((c) => c.id == classId);
    return cls?.name ?? classId;
  }


  Future<String?> resolveSubjectIdForClass(String classId) async {

    if ((subjectsByClassId[classId] ?? const []).isEmpty) {
      await fetchMySubjectsForClass(classId);
    }
    return getSubjectIdForClass(classId);
  }

  List<Map<String, String>> getSubjectsForClass(String classId) {
    final cached = subjectsByClassId[classId];
    if (cached != null && cached.isNotEmpty) return cached;

    final cls = classes.firstWhereOrNull((c) => c.id == classId);
    if (cls != null && cls.subjects.isNotEmpty) {
      return cls.subjects
          .where((s) => s.id.isNotEmpty)
          .map((s) => {'id': s.id, 'name': s.name})
          .toList();
    }


    final fromTeacherSched = teacherSchedules
        .where((sch) => sch.classId == classId && sch.subjectId.isNotEmpty)
        .map((sch) => {'id': sch.subjectId, 'name': sch.subjectName ?? ''})
        .toList();

    final map = <String, Map<String, String>>{};
    for (final s in fromTeacherSched) {
      final id = s['id'] ?? '';
      if (id.isEmpty) continue;
      map[id] = s;
    }
    return map.values.toList();
  }


  Future<void> createGradesForStudents({
    required List<String> studentIds,
    required int value,
    required String type,
    required String classId,
    required String subjectId,
    DateTime? date,
  }) async {
    for (final sid in studentIds) {
      await createGrade({
        'value': value,
        'types': type,
        'student_id': sid,
        'teacher_id': teacher.value?.id,
        'subject_id': subjectId,
        'created_at': (date ?? DateTime.now()).toIso8601String(),
      });
    }
  }

  Future<void> createHomeworkForStudents({
    required List<String> studentIds,
    required String classId,
    required String subjectId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),

      'status': 'pending',
      'subject_id': subjectId,
      'class_id': classId,
      'teacher_id': teacher.value?.id,

      if (studentIds.isNotEmpty) 'student_ids': studentIds,
    };

    await createHomework(payload);
  }

  Future<void> markAttendanceForStudent({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required String status,
    String? notes,
  }) async {
    await createAttendance({
      'attendance_date': date.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'student_id': studentId,
      'subject_id': subjectId,
      'teacher_id': teacher.value?.id,
    });
  }

  void setSelectedSubjectForClass(
    String classId, {
    required String subjectId,
    required String subjectName,
  }) {
    selectedSubjectByClassId[classId] = {
      'id': subjectId,
      'name': subjectName,
    };
  }

  String? getSubjectIdForClass(String classId) {
    final sel = selectedSubjectByClassId[classId];
    final id = sel?['id'];
    if (id != null && id.isNotEmpty) return id;

    final subs = getSubjectsForClass(classId);
    if (subs.length == 1) return subs.first['id'];
    return null;
  }

  String? getSubjectNameForClass(String classId) {
    final sel = selectedSubjectByClassId[classId];
    final name = sel?['name'];
    if (name != null && name.trim().isNotEmpty) return name;

    final subs = getSubjectsForClass(classId);
    if (subs.length == 1) return subs.first['name'];
    return null;
  }


  RxBool get isLoadingTeacherSchedule => isLoadingSchedule;


  Future<List<Map<String, String>>> fetchMySubjectsForClass(String classId) async {
    try {
      print('🔍 [TeacherDashboard] fetchMySubjectsForClass($classId)');
      final token = await SecureStorageService.getToken();
      if (token == null) {
        print('🔍 [TeacherDashboard] fetchMySubjectsForClass -> no token');
        return [];
      }

      final ds = GetIt.instance.get<TeacherRemoteDataSource>();
      final subjects = await ds.getMySubjectsForClass(classId, token);
      final mapped = subjects
          .where((s) => s.id.isNotEmpty)
          .map((s) => {'id': s.id, 'name': s.name})
          .toList();

      print('🔍 [TeacherDashboard] fetchMySubjectsForClass -> ${mapped.length} subjects');
      subjectsByClassId[classId] = mapped;
      return mapped;
    } catch (e, st) {
      print('🔍 [TeacherDashboard] fetchMySubjectsForClass error: $e');
      print('🔍 [TeacherDashboard] stack: $st');
      return [];
    }
  }



  Future<void> broadcastAnnouncement({
    required String title,
    required String message,
    List<String>? targetRoles,
  }) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) throw Exception('No token');

      final dio = await DioClient.getInstance();

      final queryParams = <String, dynamic>{
        'title': title,
        'message': message,
      };

      if (targetRoles != null && targetRoles.isNotEmpty) {
        queryParams['target_roles'] = targetRoles;
      }

      await dio.post(
        '/notifications/broadcast',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print('✅ [Director] Broadcast announcement sent successfully');
    } catch (e) {
      print('❌ [Director] Broadcast announcement error: $e');
      throw Exception('Failed to broadcast announcement: $e');
    }
  }

  Future<Map<String, dynamic>> fetchHomeroomClassReport() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) throw Exception('No token');

      final dio = await DioClient.getInstance();
      final response = await dio.get(
        '/reports/homeroom-class',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ [Homeroom] Fetch report error: $e');
      throw Exception('Failed to fetch homeroom report: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSchoolOverviewReport() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) throw Exception('No token');

      final dio = await DioClient.getInstance();
      final response = await dio.get(
        '/reports/school-overview',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ [Director] Fetch school overview error: $e');
      throw Exception('Failed to fetch school overview: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTeacherPerformanceReport() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) throw Exception('No token');

      final dio = await DioClient.getInstance();
      final response = await dio.get(
        '/reports/teacher-performance',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ [Director] Fetch teacher performance error: $e');
      throw Exception('Failed to fetch teacher performance: $e');
    }
  }


  Future<void> fetchAllTeachers() async {
    isLoadingTeachers.value = true;
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return;

      final dio = await DioClient.getInstance();
      final response = await dio.get(
        '/teachers/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        allTeachers.value = data
            .map((json) => TeacherModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print('✅ [Director] Loaded ${allTeachers.length} teachers');
      }
    } catch (e) {
      print('❌ [Director] Fetch all teachers error: $e');
      Get.snackbar(
        'Eroare',
        'Nu s-au putut încărca profesorii',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.white,
      );
    } finally {
      isLoadingTeachers.value = false;
    }
  }
}
