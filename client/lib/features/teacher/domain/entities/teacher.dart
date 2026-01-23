import 'package:equatable/equatable.dart';

import '../../data/model/teacher_model.dart';

class Teacher extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? subject;
  final bool isHomeroom;
  final bool isDirector;
  final List<SchoolClass>? classes;

  const Teacher({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.subject,
    this.isHomeroom = false,
    this.isDirector = false,
    this.classes,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    avatarUrl,
    subject,
    isHomeroom,
    isDirector,
    classes,
  ];
}
