import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_lite.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    super.key,
    this.tache,
    this.collaborateurs = const [],
    this.clients = const [],
  });

  final Tache? tache;
  final List<CollaborateurLite> collaborateurs;
  final List<ClientLite> clients;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _priorite = 'Moyenne';
  DateTime? _dateButoire;
  String? _clientId;
  String? _superviseurId;
  final Set<String> _collaborateurIds = {};
  bool _submitting = false;

  bool get _fullAssignation {
    final auth = context.read<AuthProvider>();
    return auth.canViewAllTaches || auth.isPrivilegedStaff;
  }

  @override
  void initState() {
    super.initState();
    final t = widget.tache;
    if (t != null) {
      _title.text = t.nomTache;
      _description.text = t.description ?? '';
      _priorite = t.priorite ?? 'Moyenne';
      _clientId = t.clientId;
      _superviseurId = t.superviseurId;
      _collaborateurIds.addAll(
        t.collaborateurIds.isNotEmpty
            ? t.collaborateurIds
            : (t.collaborateurId != null ? [t.collaborateurId!] : <String>[]),
      );
      if (t.dateButoire != null) {
        final p = t.dateButoire!.split('-');
        if (p.length >= 3) {
          _dateButoire = DateTime(
            int.tryParse(p[0]) ?? DateTime.now().year,
            int.tryParse(p[1]) ?? DateTime.now().month,
            int.tryParse(p[2]) ?? DateTime.now().day,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final body = <String, dynamic>{
        'nom_tache': title,
        'description': _description.text.trim(),
        'priorite': _priorite,
        'statut': widget.tache?.statut ?? 'En cours',
      };
      if (_dateButoire != null) {
        body['date_butoire'] = _fmt(_dateButoire!);
      }
      if (_clientId != null && _clientId!.isNotEmpty) {
        body['client_id'] = _clientId;
      }
      if (_fullAssignation) {
        if (_superviseurId != null && _superviseurId!.isNotEmpty) {
          body['superviseur_id'] = _superviseurId;
        }
        if (_collaborateurIds.isNotEmpty) {
          body['collaborateur_ids'] = _collaborateurIds.toList();
        }
      }
      if (widget.tache == null) {
        await auth.api.createTache(body);
      } else {
        await auth.api.patchTache(widget.tache!.id, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.tache == null ? 'Nouvelle tâche' : 'Modifier la tâche',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priorite,
              decoration: const InputDecoration(labelText: 'Priorité'),
              items: const [
                DropdownMenuItem(value: 'Haute', child: Text('Haute')),
                DropdownMenuItem(value: 'Moyenne', child: Text('Moyenne')),
                DropdownMenuItem(value: 'Basse', child: Text('Basse')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priorite = v);
              },
            ),
            if (widget.clients.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Client'),
                value: _clientId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...widget.clients.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.nomClient),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _clientId = v),
              ),
            ],
            if (_fullAssignation && widget.collaborateurs.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Superviseur'),
                value: _superviseurId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...widget.collaborateurs.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.fullName),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _superviseurId = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Collaborateur(s) assigné(s)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.collaborateurs.map((c) {
                  final selected = _collaborateurIds.contains(c.id);
                  return FilterChip(
                    label: Text(c.fullName),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _collaborateurIds.add(c.id);
                        } else {
                          _collaborateurIds.remove(c.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date butoire'),
              subtitle: Text(
                _dateButoire != null
                    ? '${_dateButoire!.day.toString().padLeft(2, '0')}/'
                          '${_dateButoire!.month.toString().padLeft(2, '0')}/'
                          '${_dateButoire!.year}'
                    : 'Optionnel',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateButoire ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setState(() => _dateButoire = picked);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.tache == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
