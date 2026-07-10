import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../models/equipe.dart';
import '../models/reclamation.dart';
import '../models/user.dart';
import '../models/message_model.dart';
import '../services/reclamation_service.dart';
import '../services/destination_service.dart';
import '../theme/app_theme.dart';
import 'agence_view.dart';
import 'notification_view.dart';
import 'reclamations_view.dart';
import 'messages_view.dart';
import 'reclamation_discussion_view.dart';
import 'chat_conversation_view.dart';
import 'new_reclamation_view.dart';
import 'profil_view.dart';

void _showHomeMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

class HomeView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const HomeView({super.key, required this.user, required this.onLogout});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  late final ReclamationService _reclamationService;
  late List<ComplaintItem> _mockComplaints;
  bool _isLoadingReceivedComplaints = false;
  String? _receivedComplaintsError;
  int _unreadNotificationCount = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<ConversationItem> _mockChats = [
    ConversationItem(
      'Support Technique',
      'Votre rÃ©clamation REQ-2026-1291 a Ã©tÃ© mise Ã  jour.',
      '09:24',
      true,
      1,
    ),
    ConversationItem(
      'Agence Casa Finance City',
      'Bonjour, nous avons bien reÃ§u les piÃ¨ces justificatives.',
      'Hier',
      false,
      0,
    ),
    ConversationItem(
      'Ahmed Benali (Client)',
      'Pouvez-vous vÃ©rifier le statut de mon virement svp ?',
      '24 Juin',
      true,
      2,
    ),
    ConversationItem(
      'Service QualitÃ©',
      'Merci pour votre retour. Le problÃ¨me est rÃ©solu.',
      '22 Juin',
      false,
      0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reclamationService = ApiReclamationService();
    _mockComplaints = <ComplaintItem>[];
    _loadReceivedComplaints();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    // Notification count from badge on bell icon
    // Will be implemented once backend notification endpoint is connected
    // For now, show 0 unless we fetch from API
    if (!mounted) return;
    setState(() {
      _unreadNotificationCount = 0;
    });
  }

  // Charge les rÃ©clamations liÃ©es Ã  l'utilisateur depuis l'API backend
  Future<void> _loadReceivedComplaints() async {
    // 1. Met Ã  jour l'Ã©tat de l'application : active l'affichage du chargement (spinner) et rÃ©initialise l'erreur
    setState(() {
      _isLoadingReceivedComplaints = true;
      _receivedComplaintsError = null;
    });
    try {
      // 2. Appel asynchrone du service pour rÃ©cupÃ©rer la liste des rÃ©clamations
      // (celles que l'utilisateur a soit crÃ©Ã©es/envoyÃ©es, soit reÃ§ues)
      final reclamations = await _reclamationService.findByUser(widget.user.id);

      if (!mounted)
        return; // SÃ©curitÃ© : si l'Ã©cran a Ã©tÃ© fermÃ© entre-temps, on arrÃªte

      // 3. Si succÃ¨s : convertit la liste brute des rÃ©clamations en modÃ¨le d'affichage (UI),
      // puis dÃ©sactive l'Ã©tat de chargement
      setState(() {
        _mockComplaints = reclamations.map(_toComplaintItem).toList();
        _isLoadingReceivedComplaints = false;
      });
    } on ReclamationException catch (error) {
      // En cas d'erreur attendue (ex: erreur de sÃ©rialisation ou retournÃ©e par l'API)
      if (!mounted) return;
      setState(() {
        _receivedComplaintsError = error
            .message; // Stocke le message d'erreur pour l'afficher Ã  l'Ã©cran
        _isLoadingReceivedComplaints = false;
      });
    } catch (_) {
      // En cas d'erreur inattendue (ex: panne rÃ©seau totale)
      if (!mounted) return;
      setState(() {
        _receivedComplaintsError = 'Impossible de joindre le serveur.';
        _isLoadingReceivedComplaints = false;
      });
    }
  }

  ComplaintItem _toComplaintItem(Reclamation reclamation) {
    final shortId = reclamation.id.length > 8
        ? reclamation.id.substring(0, 8).toUpperCase()
        : reclamation.id.toUpperCase();
    final senderName = reclamation.sender?.fullName.isNotEmpty == true
        ? reclamation.sender!.fullName
        : 'Utilisateur';
    final status = _displayStatus(reclamation.statut);
    return ComplaintItem(
      reclamation.objet,
      'REC-$shortId - De $senderName',
      status,
      _statusColor(status),
      _typeIcon(reclamation.type),
      id: reclamation.id,
      description: reclamation.description,
    );
  }

  String _displayStatus(String value) {
    final status = value.trim().toLowerCase().replaceAll('_', '');
    if (status == 'encours') return 'En cours';
    if (status == 'resolue' || status == 'resolu') return 'RÃ©solue';
    if (status == 'nouvelle') return 'Ã€ traiter';
    if (status == 'urgent') return 'Urgent';
    return value;
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('rÃ©solu') || normalized.contains('resolu')) {
      return AppColors.success;
    }
    if (normalized.contains('urgent') || normalized.contains('traiter')) {
      return AppColors.primaryRed;
    }
    return AppColors.secondaryOrange;
  }

  IconData _typeIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('carte')) return Icons.credit_card_rounded;
    if (normalized.contains('virement')) return Icons.swap_horiz_rounded;
    if (normalized.contains('connexion')) return Icons.wifi_off_rounded;
    return Icons.description_rounded;
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
      if (index == 1) {
        _loadReceivedComplaints();
      }
    }
  }

  bool get _isAdmin => widget.user.role.trim().toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    final config = _DashboardConfig.fromRole(widget.user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _TopBar(
                user: widget.user,
                config: config,
                notificationCount: _unreadNotificationCount,
                onAgencesPressed: _isAdmin
                    ? () {
                        _navigatorKeys[_selectedIndex].currentState?.push(
                          MaterialPageRoute(builder: (_) => const AgenceView()),
                        );
                      }
                    : null,
                onNotificationPressed: () {
                  _navigatorKeys[_selectedIndex].currentState?.push(
                    MaterialPageRoute(
                      builder: (_) => NotificationView(
                        primaryColor: config.primaryColor,
                        mockComplaints: _mockComplaints,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildTabNavigator(0, config),
                  _buildTabNavigator(1, config),
                  _buildTabNavigator(2, config),
                  _buildTabNavigator(3, config),
                ],
              ),
            ),
            _BottomNavigation(
              primaryColor: config.primaryColor,
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
              onAddPressed: () => _showNewComplaintSheet(config.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index, _DashboardConfig config) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _getTabContent(index, config),
        );
      },
    );
  }

  Widget _getTabContent(int index, _DashboardConfig config) {
    switch (index) {
      case 0:
        return _buildAccueilTab(config);
      case 1:
        return ReclamationsView(
          primaryColor: config.primaryColor,
          mockComplaints: _mockComplaints,
          isLoading: _isLoadingReceivedComplaints,
          error: _receivedComplaintsError,
          onRefresh: _loadReceivedComplaints,
          onComplaintTapped: _showComplaintDetail,
        );
      case 2:
        return MessagesView(
          primaryColor: config.primaryColor,
          mockChats: _mockChats,
          onChatTapped: _showChatConversation,
        );
      case 3:
        return ProfilView(
          user: widget.user,
          onLogout: widget.onLogout,
          primaryColor: config.primaryColor,
        );
      default:
        return _buildAccueilTab(config);
    }
  }

  Widget _buildAccueilTab(_DashboardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPanel(user: widget.user, config: config),
          const SizedBox(height: 22),
          _SectionHeader(
            title: config.overviewTitle,
            actionText: config.periodText,
            onPressed: () =>
                _showHomeMessage(context, 'Filtre: ${config.periodText}'),
          ),
          const SizedBox(height: 12),
          _StatsGrid(stats: config.stats),
          const SizedBox(height: 24),
          if (config.showChart) ...[
            _SectionHeader(
              title: 'Reclamations par mois',
              actionText: 'Cette annee',
              onPressed: () =>
                  _showHomeMessage(context, 'Statistiques de cette annee'),
            ),
            const SizedBox(height: 12),
            _MiniChart(color: config.primaryColor),
            const SizedBox(height: 24),
          ],
          _SectionHeader(
            title: config.listTitle,
            actionText: 'Voir tout',
            onPressed: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_isLoadingReceivedComplaints)
            const Center(child: CircularProgressIndicator())
          else if (_receivedComplaintsError != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.textLight,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _receivedComplaintsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadReceivedComplaints,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('RÃ©essayer'),
                  ),
                ],
              ),
            )
          else if (_mockComplaints.isEmpty)
            const Center(
              child: Text(
                'Aucune rÃ©clamation',
                style: TextStyle(color: AppColors.textLight),
              ),
            )
          else
            ..._mockComplaints
                .take(3)
                .map(
                  (item) => ComplaintTile(
                    item: item,
                    onTap: () => _showComplaintDetail(item),
                  ),
                ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: config.activityTitle,
            actionText: config.activityAction,
            onPressed: () => _showHomeMessage(context, config.activityTitle),
          ),
          const SizedBox(height: 10),
          ...config.activities.map((activity) => _ActivityRow(text: activity)),
        ],
      ),
    );
  }

  void _showComplaintDetail(ComplaintItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(item.icon, color: item.color),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'DÃ©tails RÃ©clamation',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.meta,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Statut: ',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description ??
                    'Traitement en cours par les Ã©quipes techniques.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showReclamationDiscussion(item);
              },
              child: const Text(
                'Ouvrir la discussion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInviteParticipantsSheet(ComplaintItem item) async {
    if (item.id.isEmpty) return;

    DestinationOptions options;
    Set<String> participantUserIds;
    try {
      options = await ApiDestinationService().loadOptions();
      participantUserIds = await _reclamationService.findParticipantUserIds(
        item.id,
      );
    } on ReclamationException catch (error) {
      if (mounted) _showHomeMessage(context, error.message);
      return;
    }
    if (!mounted) return;

    final users = options.users
        .where(
          (user) =>
              user.role.trim().toLowerCase() == 'employee_s' &&
              user.id != widget.user.id,
        )
        .toList();
    final equipes = options.equipes;

    if (users.isEmpty && equipes.isEmpty) {
      _showHomeMessage(context, 'Aucun utilisateur ou Ã©quipe Ã  inviter.');
      return;
    }

    String targetType = users.isNotEmpty ? 'USER' : 'EQUIPE';
    String? selectedUserId = users.isEmpty ? null : users.first.id;
    int? selectedEquipeId = equipes.isEmpty ? null : equipes.first.id;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submitInvitation() async {
              if ((targetType == 'USER' && selectedUserId == null) ||
                  (targetType == 'EQUIPE' && selectedEquipeId == null)) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('SÃ©lectionnez une destination.'),
                  ),
                );
                return;
              }

              if (targetType == 'USER' &&
                  participantUserIds.contains(selectedUserId)) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cet utilisateur existe dÃ©jÃ  dans la discussion.',
                    ),
                  ),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);
              try {
                await _reclamationService.inviteParticipants(
                  item.id,
                  inviterId: widget.user.id,
                  targetType: targetType,
                  userId: targetType == 'USER' ? selectedUserId : null,
                  equipeId: targetType == 'EQUIPE' ? selectedEquipeId : null,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (mounted) {
                  _showHomeMessage(
                    context,
                    targetType == 'EQUIPE'
                        ? 'Les membres de lâ€™Ã©quipe ont Ã©tÃ© invitÃ©s.'
                        : 'Lâ€™utilisateur a Ã©tÃ© invitÃ©.',
                  );
                }
              } on ReclamationException catch (error) {
                if (!sheetContext.mounted) return;
                setSheetState(() => isSubmitting = false);
                ScaffoldMessenger.of(
                  sheetContext,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Inviter Ã  la discussion',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (users.isNotEmpty)
                        ChoiceChip(
                          label: const Text('Utilisateur EMPLOYEE_S'),
                          selected: targetType == 'USER',
                          onSelected: isSubmitting
                              ? null
                              : (_) {
                                  setSheetState(() => targetType = 'USER');
                                },
                        ),
                      if (equipes.isNotEmpty)
                        ChoiceChip(
                          label: const Text('Ã‰quipe'),
                          selected: targetType == 'EQUIPE',
                          onSelected: isSubmitting
                              ? null
                              : (_) {
                                  setSheetState(() => targetType = 'EQUIPE');
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (targetType == 'USER')
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Utilisateur Ã  inviter',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      items: users.map((user) {
                        final alreadyExists = participantUserIds.contains(
                          user.id,
                        );
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: user.name),
                                if (alreadyExists)
                                  const TextSpan(
                                    text: '  Existe',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setSheetState(() => selectedUserId = value);
                            },
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedEquipeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ã‰quipe Ã  inviter',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: equipes.map((equipe) {
                        return DropdownMenuItem<int>(
                          value: equipe.id,
                          child: Text(
                            equipe.nom!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setSheetState(() => selectedEquipeId = value);
                            },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        isSubmitting ||
                            (targetType == 'USER' &&
                                participantUserIds.contains(selectedUserId))
                        ? null
                        : submitInvitation,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('INVITER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReclamationDiscussion(ComplaintItem item) {
    _navigatorKeys[_selectedIndex].currentState?.push(
      MaterialPageRoute(
        builder: (context) => ReclamationDiscussionView(
          item: item,
          user: widget.user,
          reclamationService: _reclamationService,
          onInviteParticipant: () => _showInviteParticipantsSheet(item),
        ),
      ),
    );
  }

  void _showChatConversation(ConversationItem chat) {
    _navigatorKeys[_selectedIndex].currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatConversationView(chat: chat),
      ),
    );
  }

  Future<void> _showNewComplaintSheet(Color primaryColor) async {
    List<EquipeOption> equipes;
    try {
      equipes = await ApiDestinationService().loadEquipes();
    } on ReclamationException catch (error) {
      if (mounted) _showHomeMessage(context, error.message);
      return;
    } catch (_) {
      if (mounted) {
        _showHomeMessage(context, 'Impossible de charger les équipes.');
      }
      return;
    }

    if (!mounted) return;
    if (equipes.isEmpty) {
      _showHomeMessage(
        context,
        'Aucune équipe active n’est disponible comme destinataire.',
      );
      return;
    }

    _navigatorKeys[_selectedIndex].currentState?.push(
      MaterialPageRoute(
        builder: (_) => NewReclamationView(
          user: widget.user,
          primaryColor: primaryColor,
          equipes: equipes,
          reclamationService: _reclamationService,
          onReclamationCreated: (item) {
            setState(() {
              _mockComplaints.insert(0, item);
            });
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final User user;
  final _DashboardConfig config;
  final VoidCallback? onAgencesPressed;
  final VoidCallback? onNotificationPressed;
  final int notificationCount;

  const _TopBar({
    required this.user,
    required this.config,
    this.onAgencesPressed,
    this.onNotificationPressed,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brandBlack,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.dashboard_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                config.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (onAgencesPressed != null)
          IconButton(
            tooltip: 'G+®rer les agences',
            onPressed: onAgencesPressed,
            icon: const Icon(Icons.account_balance_rounded),
          ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotificationPressed,
          icon: notificationCount > 0
              ? Badge(
                  label: Text(
                    '$notificationCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: config.primaryColor,
                  child: const Icon(Icons.notifications_none_rounded),
                )
              : const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final User user;
  final _DashboardConfig config;

  const _HeroPanel({required this.user, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [config.secondaryColor, config.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${config.greeting}, ${user.prenom.isEmpty ? user.nom : user.prenom}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.heroText,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.35,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(65)),
            ),
            child: Icon(config.heroIcon, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryRed,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_DashboardStat> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) => _StatCard(stat: stats[index]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _DashboardStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stat.color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stat.color.withAlpha(35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stat.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final Color color;

  const _MiniChart({required this.color});

  @override
  Widget build(BuildContext context) {
    const values = [0.28, 0.62, 0.45, 0.74, 0.52, 0.81, 0.66, 0.72, 0.90];

    return Container(
      height: 126,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(130)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FractionallySizedBox(
                    heightFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondaryOrange.withAlpha(210),
                            color,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String text;

  const _ActivityRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final Color primaryColor;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  const _BottomNavigation({
    required this.primaryColor,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Accueil',
            color: primaryColor,
            selected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _NavItem(
            icon: Icons.description_outlined,
            label: 'Reclamations',
            color: primaryColor,
            selected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withAlpha(75),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.message_outlined,
            label: 'Messages',
            color: primaryColor,
            selected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            color: primaryColor,
            selected: selectedIndex == 3,
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.color = AppColors.textLight,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? color : AppColors.textLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardConfig {
  final String title;
  final String subtitle;
  final String greeting;
  final String heroText;
  final String overviewTitle;
  final String periodText;
  final String listTitle;
  final String activityTitle;
  final String activityAction;
  final IconData heroIcon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showChart;
  final List<_DashboardStat> stats;
  final List<ComplaintItem> complaints;
  final List<String> activities;

  const _DashboardConfig({
    required this.title,
    required this.subtitle,
    required this.greeting,
    required this.heroText,
    required this.overviewTitle,
    required this.periodText,
    required this.listTitle,
    required this.activityTitle,
    required this.activityAction,
    required this.heroIcon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.showChart,
    required this.stats,
    required this.complaints,
    required this.activities,
  });

  factory _DashboardConfig.fromRole(String role) {
    final normalizedRole = role.trim().toLowerCase().replaceAll('-', '_');

    switch (normalizedRole) {
      case 'admin':
        return const _DashboardConfig(
          title: 'Admin',
          subtitle: 'Super administrateur',
          greeting: 'Bonjour Admin',
          heroText:
              'Voici un apercu global de la plateforme et des traitements.',
          overviewTitle: 'Vue d\'ensemble',
          periodText: 'Aujourd\'hui',
          listTitle: 'Reclamations recentes',
          activityTitle: 'Activite recente',
          activityAction: 'Tout voir',
          heroIcon: Icons.admin_panel_settings_rounded,
          primaryColor: AppColors.primaryRed,
          secondaryColor: AppColors.brandBlack,
          showChart: true,
          stats: [
            _DashboardStat(
              'Total reclamations',
              '1.248',
              '+12.5%',
              Icons.assignment_rounded,
              AppColors.primaryRed,
            ),
            _DashboardStat(
              'En cours',
              '326',
              '+8.3%',
              Icons.timelapse_rounded,
              AppColors.secondaryOrange,
            ),
            _DashboardStat(
              'Resolues',
              '768',
              '+15.7%',
              Icons.verified_rounded,
              AppColors.success,
            ),
            _DashboardStat(
              'Utilisateurs',
              '532',
              '+6.1%',
              Icons.groups_rounded,
              Color(0xFF5B2CC9),
            ),
          ],
          complaints: [
            ComplaintItem(
              'Probleme carte bancaire',
              'REQ-2026-1291 - Agence Casa Finance City',
              'En cours',
              AppColors.secondaryOrange,
              Icons.credit_card_rounded,
            ),
            ComplaintItem(
              'Erreur lors du virement',
              'REQ-2026-1257 - Agence Rabat Centre',
              'Resolue',
              AppColors.success,
              Icons.swap_horiz_rounded,
            ),
            ComplaintItem(
              'Compte bloque',
              'REQ-2026-1249 - Client prioritaire',
              'Urgent',
              AppColors.primaryRed,
              Icons.lock_rounded,
            ),
          ],
          activities: [
            'Nouvelle reclamation ajoutee a REQ-2026-1291',
            'Un utilisateur a ete affecte a une agence',
            'Rapport journalier disponible pour consultation',
          ],
        );
      case 'employee_s':
      case 'emplyee_s':
        return const _DashboardConfig(
          title: 'Developpeur',
          subtitle: 'Equipe technique',
          greeting: 'Bonjour',
          heroText:
              'Voici vos reclamations assignees et les priorites techniques.',
          overviewTitle: 'Mes reclamations',
          periodText: 'Voir tout',
          listTitle: 'Mes reclamations assignees',
          activityTitle: 'Activite recente',
          activityAction: 'Voir tout',
          heroIcon: Icons.code_rounded,
          primaryColor: Color(0xFFC1121F),
          secondaryColor: AppColors.brandBlack,
          showChart: false,
          stats: [
            _DashboardStat(
              'A traiter',
              '12',
              '+3',
              Icons.build_circle_rounded,
              AppColors.primaryRed,
            ),
            _DashboardStat(
              'En cours',
              '5',
              '+2',
              Icons.sync_rounded,
              AppColors.secondaryOrange,
            ),
            _DashboardStat(
              'En attente',
              '8',
              '-1',
              Icons.pause_circle_rounded,
              Color(0xFFB66A00),
            ),
            _DashboardStat(
              'Resolues',
              '18',
              '+7',
              Icons.check_circle_rounded,
              AppColors.success,
            ),
          ],
          complaints: [
            ComplaintItem(
              'Probleme de connexion',
              'REQ-2026-1289 - Haute priorite',
              'A traiter',
              AppColors.primaryRed,
              Icons.wifi_off_rounded,
            ),
            ComplaintItem(
              'Erreur lors du virement',
              'REQ-2026-1287 - Moyenne priorite',
              'En cours',
              AppColors.secondaryOrange,
              Icons.swap_horiz_rounded,
            ),
            ComplaintItem(
              'Lenteur de l\'application',
              'REQ-2026-1278 - Moyenne priorite',
              'Resolue',
              AppColors.success,
              Icons.speed_rounded,
            ),
          ],
          activities: [
            'Nouvelle piece jointe ajoutee a REQ-2026-1289',
            'Vous avez repondu a REQ-2026-1287',
            'Reclamation REQ-2026-1281 assignee a vous',
          ],
        );
      case 'employee_a':
        return const _DashboardConfig(
          title: 'Employe Agence',
          subtitle: 'Agence Casa Finance City',
          greeting: 'Bienvenue',
          heroText: 'Voici un apercu des reclamations de votre agence.',
          overviewTitle: 'Apercu de l\'agence',
          periodText: 'Mois en cours',
          listTitle: 'Reclamations recentes',
          activityTitle: 'Notifications',
          activityAction: 'Voir tout',
          heroIcon: Icons.account_balance_rounded,
          primaryColor: Color(0xFF0F7A4D),
          secondaryColor: AppColors.brandBlack,
          showChart: false,
          stats: [
            _DashboardStat(
              'Recues',
              '87',
              '+10.2%',
              Icons.inbox_rounded,
              AppColors.primaryRed,
            ),
            _DashboardStat(
              'En cours',
              '23',
              '+5.1%',
              Icons.pending_actions_rounded,
              AppColors.secondaryOrange,
            ),
            _DashboardStat(
              'Resolues',
              '60',
              '+15.3%',
              Icons.verified_rounded,
              AppColors.success,
            ),
            _DashboardStat(
              'Cloturees',
              '4',
              '-20.0%',
              Icons.cancel_rounded,
              AppColors.primaryRed,
            ),
          ],
          complaints: [
            ComplaintItem(
              'Probleme carte bancaire',
              'REQ-2026-1291 - Client Ahmed Benali',
              'En cours',
              AppColors.secondaryOrange,
              Icons.credit_card_rounded,
            ),
            ComplaintItem(
              'Demande de chequier',
              'REQ-2026-1290 - Client Fatima Zahra',
              'En cours',
              AppColors.secondaryOrange,
              Icons.receipt_long_rounded,
            ),
            ComplaintItem(
              'Virement non recu',
              'REQ-2026-1288 - Client Youssef El Amrani',
              'Resolue',
              AppColors.success,
              Icons.payments_rounded,
            ),
          ],
          activities: [
            'Nouvelle reclamation REQ-2026-1292 recue',
            'Reclamation REQ-2026-1283 resolue',
            'Message client ajoute a REQ-2026-1291',
          ],
        );
      default:
        return const _DashboardConfig(
          title: 'Accueil',
          subtitle: 'Espace utilisateur',
          greeting: 'Bienvenue',
          heroText: 'Consultez vos reclamations et suivez leur avancement.',
          overviewTitle: 'Mon espace',
          periodText: 'Aujourd\'hui',
          listTitle: 'Reclamations recentes',
          activityTitle: 'Notifications',
          activityAction: 'Voir tout',
          heroIcon: Icons.person_rounded,
          primaryColor: AppColors.primaryRed,
          secondaryColor: AppColors.brandBlack,
          showChart: false,
          stats: [
            _DashboardStat(
              'Envoyees',
              '8',
              '+1',
              Icons.outbox_rounded,
              AppColors.primaryRed,
            ),
            _DashboardStat(
              'En cours',
              '3',
              '+1',
              Icons.timelapse_rounded,
              AppColors.secondaryOrange,
            ),
            _DashboardStat(
              'Resolues',
              '5',
              '+2',
              Icons.verified_rounded,
              AppColors.success,
            ),
            _DashboardStat(
              'Messages',
              '2',
              'Nouveau',
              Icons.mail_rounded,
              Color(0xFF5B2CC9),
            ),
          ],
          complaints: [
            ComplaintItem(
              'Suivi reclamation',
              'REQ-2026-1210 - Derniere mise a jour',
              'En cours',
              AppColors.secondaryOrange,
              Icons.description_rounded,
            ),
            ComplaintItem(
              'Demande traitee',
              'REQ-2026-1198 - Votre agence',
              'Resolue',
              AppColors.success,
              Icons.check_circle_rounded,
            ),
          ],
          activities: [
            'Votre derniere reclamation est en cours de traitement',
            'Une reponse est disponible dans votre messagerie',
          ],
        );
    }
  }
}

class _DashboardStat {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _DashboardStat(
    this.label,
    this.value,
    this.trend,
    this.icon,
    this.color,
  );
}
