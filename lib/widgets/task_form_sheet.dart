import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_lite.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import 'modern_select_field.dart';
import 'modern_bottom_sheet.dart';
import 'tasks/task_ui.dart';

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
    final isEdit = widget.tache != null;

    return ModernBottomSheetShell(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      margin: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.06),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
            children: [
              Center(child: modernSheetDragHandle()),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: TaskUi.gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Modifier la tâche' : 'Nouvelle tâche',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Renseignez les informations ci-dessous',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _FormSection(
                title: 'Informations',
                icon: Icons.notes_rounded,
                children: [
                  _ModernTextField(
                    controller: _title,
                    label: 'Titre',
                    required: true,
                    hint: 'Ex. Relancer le client pour facture…',
                  ),
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'Contexte, instructions…',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Planification',
                icon: Icons.event_rounded,
                children: [
                  const Text(
                    'Priorité',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PriorityPills(
                    value: _priorite,
                    onChanged: (v) => setState(() => _priorite = v),
                  ),
                  const SizedBox(height: 16),
                  _DatePickerField(
                    date: _dateButoire,
                    onPick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateButoire ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setState(() => _dateButoire = picked);
                      }
                    },
                    onClear: _dateButoire != null
                        ? () => setState(() => _dateButoire = null)
                        : null,
                  ),
                ],
              ),
              if (widget.clients.isNotEmpty) ...[
                const SizedBox(height: 20),
                _FormSection(
                  title: 'Client',
                  icon: Icons.business_rounded,
                  children: [
                    ModernSelectField<String?>(
                      label: 'Client lié',
                      hint: 'Sélectionner un client',
                      leadingIcon: Icons.storefront_outlined,
                      value: _clientId,
                      options: widget.clients
                          .map(
                            (c) => ModernSelectOption<String?>(
                              value: c.id,
                              label: c.nomClient,
                              icon: Icons.business_rounded,
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _clientId = v),
                    ),
                  ],
                ),
              ],
              if (_fullAssignation && widget.collaborateurs.isNotEmpty) ...[
                const SizedBox(height: 20),
                _FormSection(
                  title: 'Assignation',
                  icon: Icons.group_outlined,
                  children: [
                    ModernSelectField<String?>(
                      label: 'Superviseur',
                      hint: 'Choisir un superviseur',
                      leadingIcon: Icons.shield_outlined,
                      value: _superviseurId,
                      options: widget.collaborateurs
                          .map(
                            (c) => ModernSelectOption<String?>(
                              value: c.id,
                              label: c.fullName,
                              icon: Icons.shield_outlined,
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _superviseurId = v),
                    ),
                    const SizedBox(height: 16),
                    ModernMultiSelectField<String>(
                      label: 'Collaborateur(s) assigné(s)',
                      hint: 'Ajouter des collaborateurs',
                      leadingIcon: Icons.person_outline_rounded,
                      values: _collaborateurIds,
                      options: widget.collaborateurs
                          .map(
                            (c) => ModernSelectOption<String>(
                              value: c.id,
                              label: c.fullName,
                              icon: Icons.person_rounded,
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _collaborateurIds
                          ..clear()
                          ..addAll(v);
                      }),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: TaskUi.accent,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Enregistrer les modifications' : 'Créer la tâche',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AromaColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TaskUi.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AromaColors.zinc900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AromaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TaskUi.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityPills extends StatelessWidget {
  const _PriorityPills({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Basse', Icons.arrow_downward_rounded, Color(0xFF2563EB)),
      ('Moyenne', Icons.remove_rounded, Color(0xFFEA580C)),
      ('Haute', Icons.arrow_upward_rounded, Color(0xFFDC2626)),
    ];

    return Row(
      children: options.map((o) {
        final selected = value == o.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: o.$1 != 'Haute' ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(o.$1),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? o.$3.withValues(alpha: 0.12)
                        : AromaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? o.$3 : const Color(0xFFE4E4E7),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        o.$2,
                        size: 18,
                        color: selected ? o.$3 : AromaColors.zinc500,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? o.$3 : AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.date,
    required this.onPick,
    this.onClear,
  });

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? '${date!.day.toString().padLeft(2, '0')}/'
          '${date!.month.toString().padLeft(2, '0')}/'
          '${date!.year}'
        : 'Choisir une date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date butoire',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AromaColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: date != null
                      ? TaskUi.accent.withValues(alpha: 0.35)
                      : const Color(0xFFE4E4E7),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: date != null ? TaskUi.accent : AromaColors.zinc500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              date != null ? FontWeight.w500 : FontWeight.w400,
                          color: date != null
                              ? AromaColors.zinc900
                              : AromaColors.zinc500,
                        ),
                      ),
                    ),
                    if (onClear != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
