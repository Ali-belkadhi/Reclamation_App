import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ComplaintItem {
  final String id;
  final String title;
  final String meta;
  final String status;
  final Color color;
  final IconData icon;
  final String? description;

  const ComplaintItem(
    this.title,
    this.meta,
    this.status,
    this.color,
    this.icon, {
    this.id = '',
    this.description,
  });
}

class ReclamationsView extends StatefulWidget {
  final Color primaryColor;
  final List<ComplaintItem> mockComplaints;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final Function(ComplaintItem) onComplaintTapped;

  const ReclamationsView({
    super.key,
    required this.primaryColor,
    required this.mockComplaints,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onComplaintTapped,
  });

  @override
  State<ReclamationsView> createState() => _ReclamationsViewState();
}

class _ReclamationsViewState extends State<ReclamationsView> {
  String _searchQuery = '';
  String _statusFilter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.mockComplaints.where((item) {
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
                        selectedColor: widget.primaryColor.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? widget.primaryColor
                              : AppColors.textLight,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? widget.primaryColor
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
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.error != null
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
                        Text(widget.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: widget.onRefresh,
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
                    onRefresh: widget.onRefresh,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return ComplaintTile(
                          item: item,
                          onTap: () => widget.onComplaintTapped(item),
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

class ComplaintTile extends StatelessWidget {
  final ComplaintItem item;
  final VoidCallback onTap;

  const ComplaintTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.meta,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                      fontSize: 11,
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
