import 'package:dio/dio.dart';
import '../model/schedule_model.dart';
import '../../../../core/network/auth_options.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleModel>> getClassSchedule(String classId, String token);
  Future<List<ScheduleModel>> getTeacherSchedule(String teacherId, String token);
  Future<ScheduleModel> createSchedule(Map<String, dynamic> scheduleData, String token);
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> scheduleData, String token);
  Future<void> deleteSchedule(String scheduleId, String token);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final Dio dio;

  ScheduleRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ScheduleModel>> getClassSchedule(String classId, String token) async {
    print('🗓️ [ScheduleDS] GET /schedules/class/$classId');
    final response = await dio.get(
      '/schedules/class/$classId',
      options: AuthOptions.bearer(token),
    );
    print('🗓️ [ScheduleDS] status=${response.statusCode}');
    final data = response.data;
    print('🗓️ [ScheduleDS] dataType=${data.runtimeType}');
    if (data is List) {
      print('🗓️ [ScheduleDS] items=${data.length}');
    } else {
      print('🗓️ [ScheduleDS] data=$data');
    }
    return (response.data as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  @override
  Future<List<ScheduleModel>> getTeacherSchedule(String teacherId, String token) async {
    print('🗓️ [ScheduleDS] GET /schedules/teacher/$teacherId');
    final response = await dio.get(
      '/schedules/teacher/$teacherId',
      options: AuthOptions.bearer(token),
    );
    print('🗓️ [ScheduleDS] status=${response.statusCode}');
    final data = response.data;
    print('🗓️ [ScheduleDS] dataType=${data.runtimeType}');
    if (data is List) {
      print('🗓️ [ScheduleDS] items=${data.length}');
      if (data.isNotEmpty) {
        print('🗓️ [ScheduleDS] first=${data.first}');
      }
    } else {
      print('🗓️ [ScheduleDS] data=$data');
    }
    return (response.data as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  @override
  Future<ScheduleModel> createSchedule(Map<String, dynamic> scheduleData, String token) async {
    final response = await dio.post(
      '/schedules/',
      data: scheduleData,
      options: AuthOptions.bearer(token),
    );
    return ScheduleModel.fromJson(response.data);
  }

  @override
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> scheduleData, String token) async {
    final response = await dio.put(
      '/schedules/$scheduleId',
      data: scheduleData,
      options: AuthOptions.bearer(token),
    );
    return ScheduleModel.fromJson(response.data);
  }

  @override
  Future<void> deleteSchedule(String scheduleId, String token) async {
    await dio.delete(
      '/schedules/$scheduleId',
      options: AuthOptions.bearer(token),
    );
  }
}
