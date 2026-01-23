import 'package:dio/dio.dart';
import '../model/attendance_model.dart';
import '../../../../core/network/auth_options.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceModel>> getStudentAttendance(
    String studentId,
    String token,
  );

  Future<AttendanceModel> createAttendance(
    Map<String, dynamic> attendanceData,
    String token,
  );

  Future<AttendanceModel> updateAttendance(
    String attendanceId,
    Map<String, dynamic> attendanceData,
    String token,
  );

  Future<void> deleteAttendance(String attendanceId, String token);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio dio;

  AttendanceRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AttendanceModel>> getStudentAttendance(
    String studentId,
    String token,
  ) async {
    final response = await dio.get(
      '/attendance/student/$studentId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List)
        .map((json) => AttendanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<AttendanceModel> createAttendance(
    Map<String, dynamic> attendanceData,
    String token,
  ) async {
    final response = await dio.post(
      '/attendance/',
      data: attendanceData,
      options: AuthOptions.bearer(token),
    );
    return AttendanceModel.fromJson(response.data);
  }

  @override
  Future<AttendanceModel> updateAttendance(
    String attendanceId,
    Map<String, dynamic> attendanceData,
    String token,
  ) async {
    final response = await dio.put(
      '/attendance/$attendanceId',
      data: attendanceData,
      options: AuthOptions.bearer(token),
    );
    return AttendanceModel.fromJson(response.data);
  }

  @override
  Future<void> deleteAttendance(String attendanceId, String token) async {
    await dio.delete(
      '/attendance/$attendanceId',
      options: AuthOptions.bearer(token),
    );
  }
}
