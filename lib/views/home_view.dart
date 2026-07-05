import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../models/reclamation.dart';
import '../models/user.dart';
import '../models/message_model.dart';
import '../services/reclamation_service.dart';
import '../theme/app_theme.dart';
import 'agence_view.dart';

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
  String _searchQuery = '';
  String _statusFilter = 'Tous';
  late final ReclamationService _reclamationService;
  late List<_ComplaintItem> _mockComplaints;
  bool _isLoadingReceivedComplaints = false;
  String? _receivedComplaintsError;
  int _unreadNotificationCount = 0;

  final List<_ConversationItem> _mockChats = [
    _ConversationItem(
      'Support Technique',
      'Votre réclamation REQ-2026-1291 a été mise à jour.',
      '09:24',
      true,
      1,
    ),
    _ConversationItem(
      'Agence Casa Finance City',
      'Bonjour, nous avons bien reçu les pièces justificatives.',
      'Hier',
      false,
      0,
    ),
    _ConversationItem(
      'Ahmed Benali (Client)',
      'Pouvez-vous vérifier le statut de mon virement svp ?',
      '24 Juin',
      true,
      2,
    ),
    _ConversationItem(
      'Service Qualité',
      'Merci pour votre retour. Le problème est résolu.',
      '22 Juin',
      false,
      0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reclamationService = ApiReclamationService();
    _mockComplaints = <_ComplaintItem>[];
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

  Future<void> _loadReceivedComplaints() async {
    setState(() {
      _isLoadingReceivedComplaints = true;
      _receivedComplaintsError = null;
    });
    try {
      // Tous les roles : uniquement les reclamations de l'utilisateur
      // (celles qu'il a envoyees OU recues)
      final reclamations = await _reclamationService.findByUser(widget.user.id);
      if (!mounted) return;
      setState(() {
        _mockComplaints = reclamations.map(_toComplaintItem).toList();
        _isLoadingReceivedComplaints = false;
      });
    } on ReclamationException catch (error) {
      if (!mounted) return;
      setState(() {
        _receivedComplaintsError = error.message;
        _isLoadingReceivedComplaints = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _receivedComplaintsError = 'Impossible de joindre le serveur.';
        _isLoadingReceivedComplaints = false;
      });
    }
  }

  _ComplaintItem _toComplaintItem(Reclamation reclamation) {
    final shortId = reclamation.id.length > 8
        ? reclamation.id.substring(0, 8).toUpperCase()
        : reclamation.id.toUpperCase();
    final senderName = reclamation.sender?.fullName.isNotEmpty == true
        ? reclamation.sender!.fullName
        : 'Utilisateur';
    final status = _displayStatus(reclamation.statut);
    return _ComplaintItem(
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
    if (status == 'resolue' || status == 'resolu') return 'Résolue';
    if (status == 'nouvelle') return 'À traiter';
    if (status == 'urgent') return 'Urgent';
    return value;
  }

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

  IconData _typeIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('carte')) return Icons.credit_card_rounded;
    if (normalized.contains('virement')) return Icons.swap_horiz_rounded;
    if (normalized.contains('connexion')) return Icons.wifi_off_rounded;
    return Icons.description_rounded;
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _isAdmin => widget.user.role.trim().toLowerCase() == 'admin';

  void _showNotificationsPanel(Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                child: _mockComplaints.isEmpty
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
                        itemCount: _mockComplaints.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, idx) {
                          final item = _mockComplaints[idx];
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
      },
    );
  }

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
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AgenceView()),
                      )
                    : null,
                onNotificationPressed: () => _showNotificationsPanel(config.primaryColor),
              ),
            ),
            Expanded(child: _buildCurrentTabContent(config)),
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

  Widget _buildCurrentTabContent(_DashboardConfig config) {
    switch (_selectedIndex) {
      case 0:
        return _buildAccueilTab(config);
      case 1:
        return _buildReclamationsTab(config);
      case 2:
        return _buildMessagesTab(config.primaryColor);
      case 3:
        return _buildProfilTab(config.primaryColor);
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
                  const Icon(Icons.cloud_off_rounded,
                      color: AppColors.textLight, size: 36),
                  const SizedBox(height: 8),
                  Text(_receivedComplaintsError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textLight)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadReceivedComplaints,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_mockComplaints.isEmpty)
            const Center(
              child: Text('Aucune réclamation',
                  style: TextStyle(color: AppColors.textLight)),
            )
          else
            ..._mockComplaints.take(3).map(
              (item) => _ComplaintTile(
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

  Widget _buildReclamationsTab(_DashboardConfig config) {
    final filtered = (_mockComplaints).where((item) {
      final q = _searchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(q);
      final metaMatch = item.meta.toLowerCase().contains(q);
      final statusMatch = item.status.toLowerCase().contains(q);

      if (_statusFilter != 'Tous') {
        final itemStatus = item.status.trim().toLowerCase();
        final selectedFilter = _statusFilter.trim().toLowerCase();
        if (selectedFilter == 'en cours' && itemStatus != 'en cours') {
          return false;
        }
        if (selectedFilter == 'résolues' &&
            (itemStatus != 'resolue' && itemStatus != 'résolue')) {
          return false;
        }
        if (selectedFilter == 'urgents/a traiter' &&
            (itemStatus != 'urgent' && itemStatus != 'a traiter')) {
          return false;
        }
      }

      return titleMatch || metaMatch || statusMatch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liste des Réclamations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une réclamation...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'En cours', 'Résolues', 'Urgents/A traiter']
                  .map((filter) {
                    final isSelected = _statusFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _statusFilter = filter;
                            });
                          }
                        },
                        selectedColor: config.primaryColor.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? config.primaryColor
                              : AppColors.textLight,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? config.primaryColor
                                : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingReceivedComplaints
                ? const Center(child: CircularProgressIndicator())
                : _receivedComplaintsError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.textLight,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _receivedComplaintsError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadReceivedComplaints,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune réclamation reçue',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReceivedComplaints,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return _ComplaintTile(
                          item: item,
                          onTap: () => _showComplaintDetail(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(Color primaryColor) {
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
              itemCount: _mockChats.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final chat = _mockChats[index];
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
                  onTap: () => _showChatConversation(chat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilTab(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryColor.withAlpha(20),
                  child: Text(
                    widget.user.prenom.isNotEmpty
                        ? '${widget.user.prenom[0]}${widget.user.nom[0]}'
                              .toUpperCase()
                        : widget.user.nom.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user.role.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withAlpha(140)),
            ),
            child: Column(
              children: [
                _buildProfileDetailRow(
                  Icons.email_outlined,
                  'Adresse e-mail',
                  widget.user.email,
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.phone_iphone_outlined,
                  'Téléphone',
                  widget.user.telephone ?? 'Non spécifié',
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.badge_outlined,
                  'CIN',
                  widget.user.cin ?? 'Non spécifié',
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.account_balance_outlined,
                  'Agence',
                  widget.user.agence ?? 'Non spécifiée',
                ),
                if (widget.user.departementId != null) ...[
                  const Divider(color: AppColors.border, height: 24),
                  _buildProfileDetailRow(
                    Icons.business_outlined,
                    'Département ID',
                    widget.user.departementId!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                debugPrint('Déconnexion cliquée...');
                widget.onLogout();
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryRed,
              ),
              label: const Text(
                'SE DÉCONNECTER',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComplaintDetail(_ComplaintItem item) {
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
                  'Détails Réclamation',
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
                    'Traitement en cours par les équipes techniques.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  void _showReclamationDiscussion(_ComplaintItem item) {
    final msgController = TextEditingController();
    final ScrollController scrollController = ScrollController();
    List<ReclamationMessage> messages = [];
    bool isLoading = true;
    String? errorMsg;
    StompClient? stompClient;
    bool isSending = false;

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Start Stomp Client and fetch messages initially
            if (stompClient == null && item.id.isNotEmpty) {
              _reclamationService.findMessages(item.id).then((list) {
                if (context.mounted) {
                  setSheetState(() {
                    messages = list;
                    isLoading = false;
                  });
                  scrollToBottom();
                }
              }).catchError((err) {
                if (context.mounted) {
                  setSheetState(() {
                    isLoading = false;
                    errorMsg = err.toString();
                  });
                }
              });

              // Setup Stomp client for real-time WebSocket connection
              final wsUrl = ApiConfig.baseUrl
                  .replaceAll('http://', 'ws://')
                  .replaceAll('https://', 'wss://') + '/ws';
              
              stompClient = StompClient(
                config: StompConfig(
                  url: wsUrl,
                  onConnect: (StompFrame frame) {
                    stompClient?.subscribe(
                      destination: '/topic/reclamations/${item.id}',
                      callback: (StompFrame frame) {
                        if (frame.body != null) {
                          try {
                            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
                            final event = data['event'] as String?;
                            if (event == 'MESSAGE_CREATED') {
                              final msgJson = data['message'] as Map<String, dynamic>;
                              final newMsg = ReclamationMessage.fromJson(msgJson);
                              if (!messages.any((m) => m.id == newMsg.id) && context.mounted) {
                                setSheetState(() {
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
                  onWebSocketError: (dynamic error) => debugPrint('STOMP WS Error: $error'),
                  onDisconnect: (frame) => debugPrint('STOMP WS Disconnected'),
                ),
              );
              stompClient?.activate();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  // Handle/bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header Row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Text(
                              'En ligne',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 10,
                            color: item.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border),
                  // Description card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 6),
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
                            Icon(Icons.description_outlined, size: 14, color: AppColors.primaryRed),
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
                          item.description ?? 'Aucune description.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                                                padding: const EdgeInsets.only(left: 6, bottom: 2),
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
                                                    backgroundColor: AppColors.primaryRed.withAlpha(20),
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
                                                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
                  // Input Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
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
                                onPressed: () async {
                                  final text = msgController.text.trim();
                                  if (text.isEmpty) return;
                                  msgController.clear();

                                  setSheetState(() {
                                    isSending = true;
                                  });

                                  try {
                                    final newMsg = await _reclamationService.sendMessage(
                                      item.id,
                                      senderId: widget.user.id,
                                      content: text,
                                    );
                                    setSheetState(() {
                                      messages.add(newMsg);
                                      isSending = false;
                                    });
                                    scrollToBottom();
                                  } catch (e) {
                                    setSheetState(() {
                                      isSending = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      stompClient?.deactivate();
    });
  }

  void _showChatConversation(_ConversationItem chat) {
    final msgController = TextEditingController();
    final List<Map<String, dynamic>> messages = [
      {'sender': 'them', 'text': chat.lastMessage, 'time': 'Aujourd\'hui'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryRed.withAlpha(20),
                        child: const Icon(
                          Icons.person_rounded,
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
                              chat.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                    ],
                  ),
                  const Divider(color: AppColors.border),
                  Expanded(
                    child: ListView.builder(
                      itemCount: messages.length,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemBuilder: (context, idx) {
                        final msg = messages[idx];
                        final isMe = msg['sender'] == 'me';
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
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
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'],
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
                                    msg['time'],
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
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryRed,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            if (msgController.text.trim().isEmpty) return;
                            setSheetState(() {
                              messages.add({
                                'sender': 'me',
                                'text': msgController.text,
                                'time': 'À l\'instant',
                              });
                            });
                            msgController.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNewComplaintSheet(Color primaryColor) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Carte bancaire';
    String priority = 'Moyenne';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nouvelle Réclamation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Objet / Titre',
                        hintText: 'Ex: Carte avalée, Virement non reçu...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description détaillée',
                        hintText: 'Expliquez en détail votre problème...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Catégorie',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          [
                                'Carte bancaire',
                                'Virement/Paiement',
                                'E-Banking',
                                'Frais & Tarification',
                                'Autre',
                              ]
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Urgence',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Faible', 'Moyenne', 'Haute'].map((pr) {
                        final isSel = priority == pr;
                        final prColor = pr == 'Haute'
                            ? AppColors.primaryRed
                            : (pr == 'Moyenne'
                                  ? AppColors.secondaryOrange
                                  : AppColors.success);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                priority = pr;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? prColor.withAlpha(25)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSel ? prColor : AppColors.border,
                                  width: isSel ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pr,
                                style: TextStyle(
                                  color: isSel ? prColor : AppColors.textLight,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty ||
                            descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez remplir tous les champs obligatoires.',
                              ),
                            ),
                          );
                          return;
                        }

                        final newId =
                            'REQ-2026-${1300 + _mockComplaints.length}';
                        final newIcon = category == 'Carte bancaire'
                            ? Icons.credit_card_rounded
                            : (category == 'E-Banking'
                                  ? Icons.computer_rounded
                                  : Icons.description_rounded);
                        final newStatus = priority == 'Haute'
                            ? 'Urgent'
                            : 'En cours';
                        final statColor = priority == 'Haute'
                            ? AppColors.primaryRed
                            : (priority == 'Moyenne'
                                  ? AppColors.secondaryOrange
                                  : AppColors.success);

                        setState(() {
                          _mockComplaints.insert(
                            0,
                            _ComplaintItem(
                              titleController.text,
                              '$newId - Créé par ${widget.user.name}',
                              newStatus,
                              statColor,
                              newIcon,
                            ),
                          );
                        });

                        Navigator.of(context).pop();

                        _showHomeMessage(
                          context,
                          'Réclamation enregistrée avec succès sous la référence $newId.',
                        );
                      },
                      child: const Text(
                        'SOUMETTRE LA RÉCLAMATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            tooltip: 'Gérer les agences',
            onPressed: onAgencesPressed,
            icon: const Icon(Icons.account_balance_rounded),
          ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotificationPressed,
          icon: notificationCount > 0
              ? Badge(
                  label: Text('$notificationCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
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

class _ComplaintTile extends StatelessWidget {
  final _ComplaintItem item;
  final VoidCallback? onTap;

  const _ComplaintTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withAlpha(140)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final List<_ComplaintItem> complaints;
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
            _ComplaintItem(
              'Probleme carte bancaire',
              'REQ-2026-1291 - Agence Casa Finance City',
              'En cours',
              AppColors.secondaryOrange,
              Icons.credit_card_rounded,
            ),
            _ComplaintItem(
              'Erreur lors du virement',
              'REQ-2026-1257 - Agence Rabat Centre',
              'Resolue',
              AppColors.success,
              Icons.swap_horiz_rounded,
            ),
            _ComplaintItem(
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
            _ComplaintItem(
              'Probleme de connexion',
              'REQ-2026-1289 - Haute priorite',
              'A traiter',
              AppColors.primaryRed,
              Icons.wifi_off_rounded,
            ),
            _ComplaintItem(
              'Erreur lors du virement',
              'REQ-2026-1287 - Moyenne priorite',
              'En cours',
              AppColors.secondaryOrange,
              Icons.swap_horiz_rounded,
            ),
            _ComplaintItem(
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
            _ComplaintItem(
              'Probleme carte bancaire',
              'REQ-2026-1291 - Client Ahmed Benali',
              'En cours',
              AppColors.secondaryOrange,
              Icons.credit_card_rounded,
            ),
            _ComplaintItem(
              'Demande de chequier',
              'REQ-2026-1290 - Client Fatima Zahra',
              'En cours',
              AppColors.secondaryOrange,
              Icons.receipt_long_rounded,
            ),
            _ComplaintItem(
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
            _ComplaintItem(
              'Suivi reclamation',
              'REQ-2026-1210 - Derniere mise a jour',
              'En cours',
              AppColors.secondaryOrange,
              Icons.description_rounded,
            ),
            _ComplaintItem(
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

class _ComplaintItem {
  final String id;
  final String title;
  final String meta;
  final String status;
  final Color color;
  final IconData icon;
  final String? description;

  const _ComplaintItem(
    this.title,
    this.meta,
    this.status,
    this.color,
    this.icon, {
    this.id = '',
    this.description,
  });
}

class _ConversationItem {
  final String title;
  final String lastMessage;
  final String time;
  final bool isGroup;
  final int unreadCount;

  const _ConversationItem(
    this.title,
    this.lastMessage,
    this.time,
    this.isGroup,
    this.unreadCount,
  );
}
