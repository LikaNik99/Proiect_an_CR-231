import '../../domain/entities/school.dart';

class SchoolModel extends School {
  SchoolModel({
    required super.id,
    required super.name,
    required super.location,
    super.phone,
    super.email,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) => SchoolModel(
    id: json['id'],
    name: json['name'],
    location: json['location'],
    phone: json['phone'],
    email: json['email'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'phone': phone,
    'email': email,
  };
}
