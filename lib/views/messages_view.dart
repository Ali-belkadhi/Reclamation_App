import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConversationItem {
  final String title;
  final String lastMessage;
  final String time;
  final bool isGroup;
  final int unreadCount;

  const ConversationItem(
    this.title,
    this.lastMessage,
    this.time,
    this.isGroup,
    this.unreadCount,
  );
}

class MessagesView extends StatelessWidget {
  final Color primaryColor;
  final List<ConversationItem> mockChats;
  final Function(ConversationItem) onChatTapped;

  const MessagesView({
    super.key,
    required this.primaryColor,
    required this.mockChats,
    required this.onChatTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: mockChats.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final chat = mockChats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withAlpha(25),
                    child: Icon(
                      chat.isGroup
                          ? Icons.support_agent_rounded
                          : Icons.person_rounded,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(
                    chat.title,
                    style: TextStyle(
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat.unreadCount > 0
                          ? AppColors.textDark
                          : AppColors.textLight,
                      fontSize: 12,
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat.time,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => onChatTapped(chat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
