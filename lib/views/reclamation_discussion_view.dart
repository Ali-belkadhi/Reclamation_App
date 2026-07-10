import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/user.dart';
import '../models/message_model.dart';
import '../services/reclamation_service.dart';
import '../theme/app_theme.dart';
import 'reclamations_view.dart';
import '../config/api_config.dart';

class ReclamationDiscussionView extends StatefulWidget {
  final ComplaintItem item;
  final User user;
  final ReclamationService reclamationService;
  final VoidCallback onInviteParticipant;

  const ReclamationDiscussionView({
    super.key,
    required this.item,
    required this.user,
    required this.reclamationService,
    required this.onInviteParticipant,
  });

  @override
  State<ReclamationDiscussionView> createState() =>
      _ReclamationDiscussionViewState();
}

class _ReclamationDiscussionViewState extends State<ReclamationDiscussionView> {
  StompClient? stompClient;
  bool isLoading = true;
  String? errorMsg;
  List<ReclamationMessage> messages = [];
  bool isSending = false;

  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    if (widget.item.id.isNotEmpty) {
      widget.reclamationService
          .findMessages(widget.item.id)
          .then((list) {
            if (mounted) {
              setState(() {
                messages = list;
                isLoading = false;
              });
              scrollToBottom();
            }
          })
          .catchError((err) {
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMsg = err.toString();
              });
            }
          });

      final wsUrl =
          ApiConfig.baseUrl
              .replaceAll('http://', 'ws://')
              .replaceAll('https://', 'wss://') +
          '/ws';

      stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: (StompFrame frame) {
            stompClient?.subscribe(
              destination: '/topic/reclamations/${widget.item.id}',
              callback: (StompFrame frame) {
                if (frame.body != null) {
                  try {
                    final data =
                        jsonDecode(frame.body!) as Map<String, dynamic>;
                    final event = data['event'] as String?;
                    if (event == 'MESSAGE_CREATED') {
                      final msgJson = data['message'] as Map<String, dynamic>;
                      final newMsg = ReclamationMessage.fromJson(msgJson);
                      if (!messages.any((m) => m.id == newMsg.id) && mounted) {
                        setState(() {
                          messages.add(newMsg);
                        });
                        scrollToBottom();
                      }
                    }
                  } catch (e) {
                    debugPrint('Error parsing WebSocket frame: $e');
                  }
                }
              },
            );
          },
          onWebSocketError: (dynamic error) =>
              debugPrint('STOMP WS Error: $error'),
          onDisconnect: (frame) => debugPrint('STOMP WS Disconnected'),
        ),
      );
      stompClient?.activate();
    }
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    msgController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryRed.withAlpha(20),
              child: const Icon(
                Icons.forum_rounded,
                color: AppColors.primaryRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Text(
                    'En ligne',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.item.status,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.item.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.user.role.trim().toLowerCase() == 'employee_s')
            IconButton(
              tooltip: 'Inviter un participant',
              icon: const Icon(
                Icons.person_add_alt_outlined,
                color: AppColors.primaryRed,
              ),
              onPressed: widget.onInviteParticipant,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(color: AppColors.border, height: 1),
            // Description card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(12),
                  border: Border.all(color: AppColors.primaryRed.withAlpha(30)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: AppColors.primaryRed,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description ?? 'Aucune description.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Message Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMsg != null
                  ? Center(
                      child: Text(
                        'Une erreur est survenue: $errorMsg',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun message. Commencez la discussion !',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemBuilder: (context, idx) {
                        final msg = messages[idx];
                        final isMe = msg.sender.idUser == widget.user.id;
                        final timeStr =
                            "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}";

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 6,
                                    bottom: 2,
                                  ),
                                  child: Text(
                                    msg.sender.fullName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primaryRed
                                          .withAlpha(20),
                                      child: Text(
                                        msg.sender.prenom.isNotEmpty
                                            ? msg.sender.prenom[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? AppColors.primaryRed
                                            : AppColors.border.withAlpha(140),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe
                                              ? const Radius.circular(16)
                                              : Radius.zero,
                                          bottomRight: isMe
                                              ? Radius.zero
                                              : const Radius.circular(16),
                                        ),
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.content,
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : AppColors.textDark,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              timeStr,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white70
                                                    : AppColors.textLight,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  isSending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: AppColors.primaryRed,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;
    msgController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final newMsg = await widget.reclamationService.sendMessage(
        widget.item.id,
        senderId: widget.user.id,
        content: text,
      );
      if (mounted) {
        setState(() {
          if (!messages.any((message) => message.id == newMsg.id)) {
            messages.add(newMsg);
          }
          isSending = false;
        });
        scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSending = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
