import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/equipe.dart';
import '../services/reclamation_service.dart';
import '../theme/app_theme.dart';
import 'reclamations_view.dart';

class NewReclamationView extends StatefulWidget {
  final User user;
  final Color primaryColor;
  final List<EquipeOption> equipes;
  final ReclamationService reclamationService;
  final Function(ComplaintItem) onReclamationCreated;

  const NewReclamationView({
    super.key,
    required this.user,
    required this.primaryColor,
    required this.equipes,
    required this.reclamationService,
    required this.onReclamationCreated,
  });

  @override
  State<NewReclamationView> createState() => _NewReclamationViewState();
}

class _NewReclamationViewState extends State<NewReclamationView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Carte bancaire';
  String _priority = 'Moyenne';
  late int? _selectedEquipeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedEquipeId = widget.equipes.isNotEmpty ? widget.equipes.first.id : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final objet = _titleController.text.trim();
    final description = _descController.text.trim();
    if (objet.isEmpty || description.isEmpty || _selectedEquipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs et choisir une équipe.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reclamation = await widget.reclamationService.create(
        senderId: widget.user.id,
        objet: objet,
        type: _category,
        description: description,
        priorite: _priority == 'Haute'
            ? 'HAUTE'
            : (_priority == 'Faible' ? 'BASSE' : 'NORMALE'),
        destinationType: 'EQUIPE',
        destinationId: _selectedEquipeId,
      );
      if (!mounted) return;
      
      // Notify parent to add the item to the list
      widget.onReclamationCreated(
        ComplaintItem(
          reclamation.objet,
          'REC-${reclamation.id} • ${reclamation.type}',
          'NOUVELLE',
          AppColors.secondaryOrange,
          Icons.description_rounded,
          id: reclamation.id,
          description: reclamation.description,
        ),
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réclamation ${reclamation.id} envoyée à l\'équipe.')),
      );
    } on ReclamationException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer la réclamation.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle Réclamation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Objet / Titre',
                hintText: 'Ex: Carte avalée, virement non reçu…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              enabled: !_isSubmitting,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description détaillée',
                hintText: 'Expliquez votre problème en détail…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Catégorie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                'Carte bancaire',
                'Virement/Paiement',
                'E-Banking',
                'Frais & Tarification',
                'Autre',
              ].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
            ),
            const SizedBox(height: 24),
            const Text(
              'Urgence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Faible', 'Moyenne', 'Haute'].map((value) {
                final selected = _priority == value;
                final color = value == 'Haute'
                    ? AppColors.primaryRed
                    : (value == 'Moyenne'
                        ? AppColors.secondaryOrange
                        : AppColors.success);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: _isSubmitting
                        ? null
                        : () {
                            setState(() => _priority = value);
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.withAlpha(25) : Colors.transparent,
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: selected ? color : AppColors.textLight,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Équipe destinataire',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedEquipeId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups_outlined),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.equipes.map((equipe) {
                return DropdownMenuItem<int>(
                  value: equipe.id,
                  child: Text(equipe.nom!, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() => _selectedEquipeId = value);
                    },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                disabledBackgroundColor: widget.primaryColor.withAlpha(140),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SOUMETTRE LA RÉCLAMATION',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
