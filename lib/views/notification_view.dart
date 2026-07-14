import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../services/reclamation_service.dart';

class NotificationView extends StatefulWidget {
  final Color primaryColor;
  final String idUser;

  const NotificationView({
    super.key,
    required this.primaryColor,
    required this.idUser,
  });

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  late final ReclamationService _service;

  @override
  void initState() {
    super.initState();
    _service = ApiReclamationService();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifs = await _service.getNotifications(widget.idUser);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  IconData _iconForType(String type) {
    if (type.contains('STATUS_CHANGED')) return Icons.sync_rounded;
    if (type.contains('ASSIGNED')) return Icons.person_add_alt_1_rounded;
    if (type.contains('CLOSED')) return Icons.check_circle_outline_rounded;
    if (type.contains('MESSAGE')) return Icons.chat_bubble_outline_rounded;
    return Icons.notifications_none_rounded;
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.primaryRed)))
          : _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, idx) {
                    final item = _notifications[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: widget.primaryColor.withAlpha(30),
                        child: Icon(_iconForType(item.type), color: widget.primaryColor, size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.read ? FontWeight.normal : FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.createdAt,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      trailing: !item.read ? Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        )
                      ) : null,
                    );
                  },
                ),
          ),
    );
  }

  static void show(
    BuildContext context,
    Color primaryColor,
    String idUser,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => NotificationView(
          primaryColor: primaryColor,
          idUser: idUser,
        ),
      ),
    );
  }
}
