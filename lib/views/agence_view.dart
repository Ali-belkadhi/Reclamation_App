import 'package:flutter/material.dart';

import '../models/agence.dart';
import '../services/agence_service.dart';
import '../theme/app_theme.dart';

class AgenceView extends StatefulWidget {
  final AgenceService? service;

  const AgenceView({super.key, this.service});

  @override
  State<AgenceView> createState() => _AgenceViewState();
}

class _AgenceViewState extends State<AgenceView> {
  late final AgenceService _service;
  List<Agence> _agences = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ApiAgenceService();
    _loadAgences();
  }

  Future<void> _loadAgences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final agences = await _service.findAll();
      agences.sort(
        (left, right) =>
            left.nom.toLowerCase().compareTo(right.nom.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _agences = agences;
        _isLoading = false;
      });
    } on AgenceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  List<Agence> get _filteredAgences {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _agences;
    return _agences.where((agence) {
      return agence.code.toLowerCase().contains(query) ||
          agence.nom.toLowerCase().contains(query) ||
          (agence.ville?.toLowerCase().contains(query) ?? false) ||
          (agence.directeur?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gestion des agences',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAgenceForm(),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher par code, nom, ville...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredAgences.length} agence${_filteredAgences.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadAgences,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final agences = _filteredAgences;
    if (agences.isEmpty) {
      return const Center(
        child: Text(
          'Aucune agence trouvée',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAgences,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        itemCount: agences.length,
        itemBuilder: (context, index) => _AgenceCard(
          agence: agences[index],
          onEdit: () => _showAgenceForm(agence: agences[index]),
          onDelete: () => _confirmDelete(agences[index]),
        ),
      ),
    );
  }

  Future<void> _showAgenceForm({Agence? agence}) async {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'code': TextEditingController(text: agence?.code),
      'nom': TextEditingController(text: agence?.nom),
      'adresse': TextEditingController(text: agence?.adresse),
      'ville': TextEditingController(text: agence?.ville),
      'telephone': TextEditingController(text: agence?.telephone),
      'email': TextEditingController(text: agence?.email),
      'directeur': TextEditingController(text: agence?.directeur),
    };
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => isSaving = true);
            final value = Agence(
              idAgence: agence?.idAgence ?? 0,
              code: controllers['code']!.text.trim(),
              nom: controllers['nom']!.text.trim(),
              adresse: _emptyToNull(controllers['adresse']!.text),
              ville: _emptyToNull(controllers['ville']!.text),
              telephone: _emptyToNull(controllers['telephone']!.text),
              email: _emptyToNull(controllers['email']!.text),
              directeur: _emptyToNull(controllers['directeur']!.text),
              dateCreation: agence?.dateCreation,
            );
            try {
              agence == null
                  ? await _service.create(value)
                  : await _service.update(value);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              await _loadAgences();
              if (mounted) {
                _showMessage(
                  agence == null
                      ? 'Agence ajoutée avec succès.'
                      : 'Agence modifiée avec succès.',
                );
              }
            } on AgenceException catch (error) {
              if (!dialogContext.mounted) return;
              setDialogState(() => isSaving = false);
              _showMessage(error.message, isError: true);
            }
          }

          return AlertDialog(
            title: Text(
              agence == null ? 'Nouvelle agence' : 'Modifier l’agence',
            ),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field(
                        controllers['code']!,
                        'Code *',
                        maxLength: 20,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controllers['nom']!,
                        'Nom *',
                        maxLength: 100,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controllers['adresse']!,
                        'Adresse',
                        maxLength: 255,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _field(controllers['ville']!, 'Ville', maxLength: 100),
                      const SizedBox(height: 12),
                      _field(
                        controllers['telephone']!,
                        'Téléphone',
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controllers['email']!,
                        'Email',
                        maxLength: 100,
                        keyboardType: TextInputType.emailAddress,
                        isEmail: true,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controllers['directeur']!,
                        'Directeur',
                        maxLength: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : save,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required int maxLength,
    bool isRequired = false,
    bool isEmail = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (isRequired && text.isEmpty) return 'Ce champ est requis.';
        if (isEmail &&
            text.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Adresse email invalide.';
        }
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Agence agence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l’agence ?'),
        content: Text(
          'L’agence « ${agence.nom} » sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(agence.idAgence);
      await _loadAgences();
      if (mounted) _showMessage('Agence supprimée avec succès.');
    } on AgenceException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  String? _emptyToNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _AgenceCard extends StatelessWidget {
  final Agence agence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgenceCard({
    required this.agence,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agence.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agence.code,
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (agence.ville != null)
                    _detail(Icons.location_on_outlined, agence.ville!),
                  if (agence.adresse != null)
                    _detail(Icons.map_outlined, agence.adresse!),
                  if (agence.directeur != null)
                    _detail(Icons.person_outline_rounded, agence.directeur!),
                  if (agence.telephone != null)
                    _detail(Icons.phone_outlined, agence.telephone!),
                  if (agence.email != null)
                    _detail(Icons.email_outlined, agence.email!),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Modifier'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
