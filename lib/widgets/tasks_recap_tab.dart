import 'package:flutter/material.dart';

import '../models/tache.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';

class TasksRecapTab extends StatelessWidget {
  const TasksRecapTab({
    super.key,
    required this.tasks,
    required this.collaborateurs,
    required this.currentCollaborateurId,
    required this.isExecutive,
    required this.monthKey,
    required this.onMonthChanged,
    this.selectedCollaborateurId,
    this.onCollaborateurChanged,
  });

  final List<Tache> tasks;
  final List<CollaborateurLite> collaborateurs;
  final String? currentCollaborateurId;
  final bool isExecutive;
  final String monthKey;
  final ValueChanged<String> onMonthChanged;
  final String? selectedCollaborateurId;
  final ValueChanged<String?>? onCollaborateurChanged;

  DateTime _monthStart(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]));
  }

  bool _inMonth(Tache t, DateTime start, DateTime end) {
    final due = t.dateButoire;
    if (due != null && due.length >= 7) {
      final d = DateTime.tryParse(due.length >= 10 ? due : '$due-01');
      if (d != null && !d.isBefore(start) && d.isBefore(end)) return true;
    }
    if (t.isTerminee) {
      final done = DateTime.tryParse(t.dateTerminee ?? '');
      if (done != null && !done.isBefore(start) && done.isBefore(end)) {
        return true;
      }
    }
    if (!t.isTerminee && due != null) {
      final d = DateTime.tryParse(due.length >= 10 ? due : '$due-01');
      if (d != null && d.isBefore(start)) return true;
    }
    return false;
  }

  List<Tache> _forCollab(String collabId) {
    return tasks.where((t) {
      final ids = t.collaborateurIds.isNotEmpty
          ? t.collaborateurIds
          : (t.collaborateurId != null ? [t.collaborateurId!] : <String>[]);
      return ids.contains(collabId) || t.superviseurId == collabId;
    }).toList();
  }

  void _shiftMonth(int delta) {
    final start = _monthStart(monthKey);
    final next = DateTime(start.year, start.month + delta);
    onMonthChanged(
      '${next.year.toString().padLeft(4, '0')}-'
      '${next.month.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = _monthStart(monthKey);
    final end = DateTime(start.year, start.month + 1);
    final collabId = selectedCollaborateurId ?? currentCollaborateurId;

    if (isExecutive && selectedCollaborateurId == null) {
      final actifs = collaborateurs;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MonthHeader(
            monthKey: monthKey,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 12),
          Text(
            'Objectifs par collaborateur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...actifs.map((c) {
            final scoped = _forCollab(c.id)
                .where((t) => _inMonth(t, start, end))
                .toList();
            final done = scoped.where((t) => t.isTerminee).length;
            final total = scoped.length;
            final pct = total > 0 ? done / total * 100 : 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(c.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: total > 0 ? pct / 100 : 0,
                      backgroundColor: AromaColors.zinc100,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 4),
                    Text('$done / $total terminées (${pct.toStringAsFixed(0)} %)'),
                  ],
                ),
                onTap: () => onCollaborateurChanged?.call(c.id),
              ),
            );
          }),
        ],
      );
    }

    if (collabId == null) {
      return const Center(child: Text('Aucun collaborateur associé.'));
    }

    final scoped = _forCollab(collabId).where((t) => _inMonth(t, start, end));
    final list = scoped.toList();
    final done = list.where((t) => t.isTerminee).length;
    final total = list.length;
    final pct = total > 0 ? done / total * 100 : 0.0;
    final asSuperviseur =
        tasks.where((t) => t.superviseurId == collabId && _inMonth(t, start, end));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MonthHeader(
          monthKey: monthKey,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        if (isExecutive && onCollaborateurChanged != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(labelText: 'Collaborateur'),
            value: selectedCollaborateurId ?? collabId,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tous')),
              ...collaborateurs.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.fullName)),
              ),
            ],
            onChanged: onCollaborateurChanged,
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectifs réalisés — ${monthLabelFr(monthKey)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: total > 0 ? pct / 100 : 0,
                  minHeight: 10,
                  backgroundColor: AromaColors.zinc100,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(height: 8),
                Text('$done / $total terminées (${pct.toStringAsFixed(0)} %)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_ind_outlined),
            title: const Text('Tâches assignées'),
            trailing: Text(
              '$total',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.supervisor_account_outlined),
            title: const Text('Tâches en tant que superviseur'),
            trailing: Text(
              '${asSuperviseur.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthKey,
    required this.onPrev,
    required this.onNext,
  });

  final String monthKey;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            monthLabelFr(monthKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
