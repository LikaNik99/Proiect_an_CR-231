class MaterialModel {
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

  MaterialModel({
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
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
