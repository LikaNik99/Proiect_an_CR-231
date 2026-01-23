import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';

class AttendanceTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const AttendanceTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1D1E33),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text(
                  'Prezență',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Marcarea prezenței',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const Text(
                    'va fi disponibilă în curând',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
