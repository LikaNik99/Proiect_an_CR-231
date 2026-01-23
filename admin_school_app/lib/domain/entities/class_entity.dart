class ClassEntity {
  final String? id;
  final String name;
  final String? teacherId;
  final String schoolId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClassEntity({
    this.id,
    required this.name,
    this.teacherId,
    required this.schoolId,
    this.createdAt,
    this.updatedAt,
  });
}