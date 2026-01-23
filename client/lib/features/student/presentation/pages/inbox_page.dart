import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/notification_model.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  StudentDataApi? _api;
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    if (_api == null) {
      final dio = await DioClient.getInstance();
      _api = StudentDataApi(dio);
    }

    final notifications = await _api!.getMyNotifications();
    setState(() {
      _notifications = notifications;
      _filteredNotifications = notifications;
      _isLoading = false;
    });
  }

  void _filterNotifications(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNotifications = _notifications;
      } else {
        _filteredNotifications = _notifications
            .where((n) =>
                n.title.toLowerCase().contains(query.toLowerCase()) ||
                n.message.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _api!.markNotificationAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            notificationType: notification.notificationType,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }
        _filterNotifications(_searchQuery);
      });
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'homework':
        return Colors.orange;
      case 'grade':
        return Colors.green;
      case 'attendance':
        return Colors.red;
      case 'announcement':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'homework':
        return Icons.assignment;
      case 'grade':
        return Icons.grade;
      case 'attendance':
        return Icons.event_busy;
      case 'announcement':
        return Icons.announcement;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Acum';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}z';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF111827)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'inbox_title'.tr,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterNotifications,
              ),
            ),
          ),
          const SizedBox(height: 12),


          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: _filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.notifications_off
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Nu ai notificări'
                                      : 'Nicio notificare găsită',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredNotifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final notification = _filteredNotifications[index];
                              return InkWell(
                                onTap: () => _markAsRead(notification),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: notification.isRead
                                          ? [const Color(0xFF1A1C20), const Color(0xFF111827)]
                                          : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: notification.isRead
                                          ? Colors.white.withOpacity(0.1)
                                          : _getTypeColor(notification.notificationType)
                                              .withOpacity(0.3),
                                      width: notification.isRead ? 1 : 2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(notification.notificationType)
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getTypeColor(notification.notificationType),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          _getTypeIcon(notification.notificationType),
                                          color: _getTypeColor(notification.notificationType),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notification.title,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: notification.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(notification.createdAt),
                                                  style: TextStyle(
                                                    color: notification.isRead
                                                        ? Colors.white38
                                                        : Colors.white60,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notification.message,
                                              style: TextStyle(
                                                color: notification.isRead
                                                    ? Colors.white60
                                                    : Colors.white70,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (!notification.isRead) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.blue,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Nou',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
