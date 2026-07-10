import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'reclamations_view.dart'; // For ComplaintItem

class NotificationView extends StatelessWidget {
  final Color primaryColor;
  final List<ComplaintItem> mockComplaints;

  const NotificationView({
    super.key,
    required this.primaryColor,
    required this.mockComplaints,
  });

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('résolu') || normalized.contains('resolu')) {
      return AppColors.success;
    }
    if (normalized.contains('urgent') || normalized.contains('traiter')) {
      return AppColors.primaryRed;
    }
    return AppColors.secondaryOrange;
  }

  @override
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
      body: mockComplaints.isEmpty
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
          : ListView.separated(
              itemCount: mockComplaints.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, idx) {
                final item = mockComplaints[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withAlpha(30),
                    child: Icon(item.icon, color: primaryColor, size: 20),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    item.meta,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: _statusColor(item.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  static void show(
    BuildContext context,
    Color primaryColor,
    List<ComplaintItem> mockComplaints,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => NotificationView(
          primaryColor: primaryColor,
          mockComplaints: mockComplaints,
        ),
      ),
    );
  }
}
