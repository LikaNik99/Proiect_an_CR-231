import '../../domain/entities/subject_entity.dart';

class SubjectModel extends Subject {
  const SubjectModel({
    required super.id,
    required super.name,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
