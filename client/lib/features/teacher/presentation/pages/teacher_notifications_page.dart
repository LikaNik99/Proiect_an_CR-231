import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
class TeacherNotificationsPage extends StatelessWidget {
  final TeacherDashboardController controller;
  const TeacherNotificationsPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Notificari', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white70),
            onPressed: () => Get.snackbar('Notificari', 'Toate notificarile marcate ca citite', snackPosition: SnackPosition.BOTTOM),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationItem(
            icon: Icons.add_circle_outline,
            title: 'Nota adaugata cu succes',
            description: 'Ai adaugat nota 10 pentru elevul Pricop Alexandru la Matematica',
            time: 'Acum 5 minute',
            isRead: false,
            color: Colors.green,
          ),
          _buildNotificationItem(
            icon: Icons.edit_note,
            title: 'Tema creata',
            description: 'Ai creat o tema noua pentru clasa a 9-a A',
            time: 'Acum 1 ora',
            isRead: false,
            color: Colors.blue,
          ),
          _buildNotificationItem(
            icon: Icons.schedule,
            title: 'Orar actualizat',
            description: 'Orarul tau a fost actualizat pentru saptamana viitoare',
            time: 'Ieri',
            isRead: true,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isRead,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF1A1F26) : const Color(0xFF1E2530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRead ? Colors.white10 : color.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 8),
            Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
        trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)) : null,
      ),
    );
  }
}
