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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, color: primaryColor),
                const SizedBox(width: 10),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Expanded(
            child: mockComplaints.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 48, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text(
                          'Aucune notification',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    itemCount: mockComplaints.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, idx) {
                      final item = mockComplaints[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withAlpha(30),
                          child: Icon(item.icon, color: primaryColor, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          item.meta,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(item.status).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                                fontSize: 10,
                                color: _statusColor(item.status),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, Color primaryColor, List<ComplaintItem> mockComplaints) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => NotificationView(
        primaryColor: primaryColor,
        mockComplaints: mockComplaints,
      ),
    );
  }
}
