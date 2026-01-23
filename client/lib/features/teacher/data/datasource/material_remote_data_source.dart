import 'package:dio/dio.dart';
import '../model/material_model.dart';
import '../../../../core/network/auth_options.dart';

abstract class MaterialRemoteDataSource {
  Future<List<MaterialModel>> getClassMaterials(String classId, String token);
  Future<List<MaterialModel>> getTeacherMaterials(String teacherId, String token);
  Future<MaterialModel> createMaterial(Map<String, dynamic> materialData, String token);
  Future<MaterialModel> updateMaterial(String materialId, Map<String, dynamic> materialData, String token);
  Future<void> deleteMaterial(String materialId, String token);
}

class MaterialRemoteDataSourceImpl implements MaterialRemoteDataSource {
  final Dio dio;

  MaterialRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MaterialModel>> getClassMaterials(String classId, String token) async {
    final response = await dio.get(
      '/materials/class/$classId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List).map((json) => MaterialModel.fromJson(json)).toList();
  }

  @override
  Future<List<MaterialModel>> getTeacherMaterials(String teacherId, String token) async {
    final response = await dio.get(
      '/materials/teacher/$teacherId',
      options: AuthOptions.bearer(token),
    );
    return (response.data as List).map((json) => MaterialModel.fromJson(json)).toList();
  }

  @override
  Future<MaterialModel> createMaterial(Map<String, dynamic> materialData, String token) async {
    final response = await dio.post(
      '/materials/',
      data: materialData,
      options: AuthOptions.bearer(token),
    );
    return MaterialModel.fromJson(response.data);
  }

  @override
  Future<MaterialModel> updateMaterial(String materialId, Map<String, dynamic> materialData, String token) async {
    final response = await dio.put(
      '/materials/$materialId',
      data: materialData,
      options: AuthOptions.bearer(token),
    );
    return MaterialModel.fromJson(response.data);
  }

  @override
  Future<void> deleteMaterial(String materialId, String token) async {
    await dio.delete(
      '/materials/$materialId',
      options: AuthOptions.bearer(token),
    );
  }
}
