import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/teacher_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(130);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherController());

    return Obx(() {
      final teacher = controller.teacher.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Text(
                  teacher?.username.substring(0, 1).toUpperCase() ?? "?",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Panou Profesor",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher != null
                          ? "Prof. ${teacher.username}"
                          : "Se încarcă...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications_none, color: Colors.white70),
            ],
          ),
        ),
      );
    });
  }
}
