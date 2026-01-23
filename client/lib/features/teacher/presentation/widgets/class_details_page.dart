import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../student/data/model/student.dart';
import '../../data/model/teacher_model.dart';
import '../controllers/teacher_dashboard_controller.dart';
import 'students_catalog.dart';

class ClassDetailsPage extends StatelessWidget {
  final SchoolClass schoolClass;
  final TeacherDashboardController controller;

  const ClassDetailsPage({
    super.key,
    required this.schoolClass,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: StudentsCatalog(
        schoolClass: schoolClass,
        controller: controller,
      ),
    );
  }
}
