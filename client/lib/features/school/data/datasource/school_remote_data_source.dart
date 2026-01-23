import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/network/auth_options.dart';
import '../models/school_model.dart';

abstract class SchoolRemoteDataSource {
  Future<List<SchoolModel>> getAllSchools({required String token});

  Future<SchoolModel?> getSchoolById(String id, {required String token});

  Future<SchoolModel?> createSchool(
    SchoolModel school, {
    required String token,
  });

  Future<SchoolModel?> updateSchool(
    String id,
    SchoolModel school, {
    required String token,
  });

  Future<bool> deleteSchool(String id, {required String token});
}

class SchoolRemoteDataSourceImpl implements SchoolRemoteDataSource {
  final Dio dio;

  SchoolRemoteDataSourceImpl(this.dio);

  final String baseUrl = '/schools';

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE57373),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  @override
  Future<List<SchoolModel>> getAllSchools({required String token}) async {
    try {
      final response = await dio.get(
        '$baseUrl/',
        options: AuthOptions.bearer(token),
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => SchoolModel.fromJson(json))
            .toList();
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _showError(e.response?.data.toString() ?? 'Dio error');
    } catch (e) {
      _showError(e.toString());
    }
    return [];
  }

  @override
  Future<SchoolModel?> getSchoolById(String id, {required String token}) async {
    try {
      final response = await dio.get(
        '$baseUrl/$id',
        options: AuthOptions.bearer(token),
      );
      if (response.statusCode == 200) {
        return SchoolModel.fromJson(response.data);
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _showError(e.response?.data.toString() ?? 'Dio error');
    } catch (e) {
      _showError(e.toString());
    }
    return null;
  }

  @override
  Future<SchoolModel?> createSchool(
    SchoolModel school, {
    required String token,
  }) async {
    try {
      final response = await dio.post(
        "$baseUrl/",
        data: school.toJson(),
        options: AuthOptions.bearer(token),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SchoolModel.fromJson(response.data);
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _showError(e.response?.data.toString() ?? 'Dio error');
    } catch (e) {
      _showError(e.toString());
    }
    return null;
  }

  @override
  Future<SchoolModel?> updateSchool(
    String id,
    SchoolModel school, {
    required String token,
  }) async {
    try {
      final response = await dio.put(
        '$baseUrl/$id',
        data: school.toJson(),
        options: AuthOptions.bearer(token),
      );
      if (response.statusCode == 200) {
        return SchoolModel.fromJson(response.data);
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _showError(e.response?.data.toString() ?? 'Dio error');
    } catch (e) {
      _showError(e.toString());
    }
    return null;
  }

  @override
  Future<bool> deleteSchool(String id, {required String token}) async {
    try {
      final response = await dio.delete(
        '$baseUrl/$id',
        options: AuthOptions.bearer(token),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _showError(e.response?.data.toString() ?? 'Dio error');
    } catch (e) {
      _showError(e.toString());
    }
    return false;
  }
}
