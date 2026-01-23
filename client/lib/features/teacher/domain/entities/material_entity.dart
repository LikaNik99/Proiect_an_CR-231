import 'package:equatable/equatable.dart';

class Material extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  final String subjectId;
  final String? subjectName;
  final String classId;
  final String teacherId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Material({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
    required this.subjectId,
    this.subjectName,
    required this.classId,
    required this.teacherId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        fileUrl,
        fileName,
        fileSize,
        subjectId,
        subjectName,
        classId,
        teacherId,
        createdAt,
        updatedAt,
      ];
}
