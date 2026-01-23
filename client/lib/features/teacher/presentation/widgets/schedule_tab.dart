import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';

class ScheduleTab extends StatelessWidget {
  final TeacherDashboardController controller;

  const ScheduleTab({super.key, required this.controller});

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
                Icon(Icons.schedule, color: Colors.purple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Orar',
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
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Vizualizarea orarului',
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
