import 'package:dio/dio.dart';

import '../model/student.dart';

abstract class StudentRemoteDataSource {
  Future<List<StudentModel>> getAll();
  Future<StudentModel> getById(String id);
  Future<StudentModel> create(StudentModel student);
  Future<StudentModel> update(String id, StudentModel student);
  Future<void> delete(String id);
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final Dio dio;
  StudentRemoteDataSourceImpl(this.dio);

  @override
  Future<List<StudentModel>> getAll() async {
    final res = await dio.get("/students/");

    return (res.data as List)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  }

  @override
  Future<StudentModel> getById(String id) async {
    final res = await dio.get("/students/$id");
    return StudentModel.fromJson(res.data);
  }

  @override
  Future<StudentModel> create(StudentModel student) async {
    final res = await dio.post("/students/", data: student.toJson());
    return StudentModel.fromJson(res.data);
  }

  @override
  Future<StudentModel> update(String id, StudentModel student) async {
    final res = await dio.put("/students/$id", data: student.toJson());
    return StudentModel.fromJson(res.data);
  }

  @override
  Future<void> delete(String id) async {
    await dio.delete("/students/$id");
  }
}
