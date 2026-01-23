import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_dashboard_controller.dart';
class StudentNotificationsPage extends StatelessWidget {
  final StudentDashboardController controller;
  const StudentNotificationsPage({super.key, required this.controller});
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
            onPressed: () async {
              for (var notif in controller.notifications.where((n) => !n.isRead)) {
                await controller.markNotificationAsRead(notif.id);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingNotifications.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        final notifications = controller.notifications;
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text('Nu ai notificari', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _buildNotificationItem(
              icon: _getIconForType(notif.notificationType),
              title: notif.title,
              description: notif.message,
              time: _formatTime(notif.createdAt),
              isRead: notif.isRead,
              color: _getColorForType(notif.notificationType),
              onTap: () => controller.markNotificationAsRead(notif.id),
            );
          },
        );
      }),
    );
  }
  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isRead,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_grade': return Icons.add_circle_outline;
      case 'new_homework': return Icons.assignment;
      case 'absence': return Icons.warning_amber;
      case 'schedule_change': return Icons.schedule;
      default: return Icons.notifications;
    }
  }
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_grade': return Colors.green;
      case 'new_homework': return Colors.blue;
      case 'absence': return Colors.red;
      case 'schedule_change': return Colors.orange;
      default: return Colors.grey;
    }
  }
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return 'Acum ${diff.inMinutes} minute';
    if (diff.inHours < 24) return 'Acum ${diff.inHours} ore';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return 'Acum ${diff.inDays} zile';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
