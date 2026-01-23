import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/splash_controller.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem Management',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}