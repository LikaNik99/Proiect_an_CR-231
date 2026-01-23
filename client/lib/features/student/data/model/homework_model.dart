class HomeworkModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String status;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String classId;
  final DateTime createdAt;

  HomeworkModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.classId,
    required this.createdAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: DateTime.parse(json['due_date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'] ?? 'Unknown',
      teacherId: json['teacher_id'] ?? '',
      classId: json['class_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}