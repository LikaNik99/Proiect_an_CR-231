import '../../domain/entities/material_entity.dart';

class MaterialModel extends Material {
  const MaterialModel({
    required super.id,
    required super.title,
    super.description,
    required super.fileUrl,
    required super.fileName,
    super.fileSize,
    required super.subjectId,
    super.subjectName,
    required super.classId,
    required super.teacherId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'],
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'],
      classId: json['class_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'subject_id': subjectId,
      'class_id': classId,
      'teacher_id': teacherId,
    };
  }
}
