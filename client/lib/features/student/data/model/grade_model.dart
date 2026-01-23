class GradeModel {
  final String id;
  final int value;
  final String type;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final DateTime createdAt;

  GradeModel({
    required this.id,
    required this.value,
    required this.type,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.createdAt,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] ?? '',
      value: json['value'] ?? 0,
      type: json['types'] ?? 'other',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject']?['name'] ?? 'Unknown',
      teacherId: json['teacher_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'types': type,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}