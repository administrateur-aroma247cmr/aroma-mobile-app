import 'package:flutter/material.dart';

import '../models/tache.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import 'modern_select_field.dart';
import 'tasks/task_ui.dart';

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
  /// Direction (admin, CEO, manager) — grille tous collaborateurs.
  final bool isExecutive;
  final String monthKey;
  final ValueChanged<String> onMonthChanged;
  final String? selectedCollaborateurId;
  final ValueChanged<String?>? onCollaborateurChanged;

  DateTime _monthStart(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]));
  }

  DateTime? _parseDue(Tache t) {
    final raw = t.dateButoire;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.length >= 10 ? raw : '$raw-01');
  }

  bool _inMonthWithCarryover(Tache t, DateTime start, DateTime end) {
    final due = _parseDue(t);
    if (due == null) return false;
    final dueOnly = DateTime(due.year, due.month, due.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    if (!dueOnly.isBefore(startOnly) && !dueOnly.isAfter(endOnly)) {
      return true;
    }
    if (dueOnly.isBefore(startOnly)) {
      if (t.isTerminee) {
        final done = DateTime.tryParse(t.dateTerminee ?? '');
        if (done != null && !done.isBefore(start)) return true;
        return false;
      }
      return true;
    }
    return false;
  }

  bool _doneInMonth(Tache t, DateTime start, DateTime end) {
    if (t.isTerminee) {
      final done = DateTime.tryParse(t.dateTerminee ?? '');
      if (done != null) {
        return !done.isBefore(start) && !done.isAfter(end);
      }
      final due = _parseDue(t);
      if (due != null) {
        return !due.isBefore(start) && !due.isAfter(end);
      }
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

  List<({int week, String label, double pct})> _weekStats(
    List<Tache> scoped,
    DateTime monthStart,
  ) {
    final year = monthStart.year;
    final month = monthStart.month;
    final monthEnd = DateTime(year, month + 1, 0);
    var cursor = DateTime(year, month, 1);
    final offset = cursor.weekday - 1;
    cursor = cursor.subtract(Duration(days: offset));

    final weeks = <({int week, String label, double pct})>[];
    var weekIndex = 1;
    while (cursor.isBefore(monthEnd.add(const Duration(days: 1)))) {
      final weekStart = cursor;
      final weekEnd = cursor.add(const Duration(days: 6));
      final rangeStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
      final rangeEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
      if (!rangeEnd.isBefore(monthStart)) {
        final inWeek = scoped.where((t) {
          final d = _parseDue(t);
          if (d == null) return false;
          final dd = DateTime(d.year, d.month, d.day);
          return !dd.isBefore(rangeStart) && !dd.isAfter(rangeEnd);
        }).toList();
        final done = inWeek.where((t) => t.isTerminee).length;
        final pct = inWeek.isEmpty ? 0.0 : done / inWeek.length * 100;
        weeks.add((
          week: weekIndex++,
          label:
              '${rangeStart.day}/${rangeStart.month} – ${rangeEnd.day}/${rangeEnd.month}',
          pct: pct,
        ));
      }
      cursor = cursor.add(const Duration(days: 7));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final start = _monthStart(monthKey);
    final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59);
    final collabId = selectedCollaborateurId ?? currentCollaborateurId;

    if (isExecutive && (selectedCollaborateurId == null || selectedCollaborateurId!.isEmpty)) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _RecapHeader(
            monthKey: monthKey,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          if (onCollaborateurChanged != null) ...[
            const SizedBox(height: 12),
            ModernSelectField<String?>(
              label: 'Collaborateur',
              hint: 'Tous les collaborateurs',
              leadingIcon: Icons.person_search_rounded,
              allowClear: true,
              clearLabel: 'Tous les collaborateurs',
              value: selectedCollaborateurId,
              options: collaborateurs
                  .map(
                    (c) => ModernSelectOption<String?>(
                      value: c.id,
                      label: c.fullName,
                      icon: Icons.person_rounded,
                    ),
                  )
                  .toList(),
              onChanged: onCollaborateurChanged!,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Objectifs par collaborateur — ${monthLabelFr(monthKey)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...collaborateurs.map((c) {
            final scoped = _forCollab(c.id)
                .where((t) => _inMonthWithCarryover(t, start, end))
                .toList();
            final done = scoped.where((t) => _doneInMonth(t, start, end)).length;
            final total = scoped.length;
            final pct = total > 0 ? done / total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CollabRecapCard(
                name: c.fullName,
                done: done,
                total: total,
                pct: pct,
                onTap: () => onCollaborateurChanged?.call(c.id),
              ),
            );
          }),
        ],
      );
    }

    if (collabId == null) {
      return const Center(
        child: Text('Aucun collaborateur associé à ce compte.'),
      );
    }

    final scoped = _forCollab(collabId)
        .where((t) => _inMonthWithCarryover(t, start, end))
        .toList();
    final done = scoped.where((t) => _doneInMonth(t, start, end)).length;
    final total = scoped.length;
    final pct = total > 0 ? done / total * 100 : 0.0;
    final asAssignee = scoped
        .where(
          (t) =>
              t.collaborateurIds.isNotEmpty || t.collaborateurId != null,
        )
        .length;
    final asSuperviseur =
        scoped.where((t) => t.superviseurId == collabId).length;
    final weeks = _weekStats(_forCollab(collabId), start);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _RecapHeader(
          monthKey: monthKey,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        if (isExecutive && onCollaborateurChanged != null) ...[
          const SizedBox(height: 12),
          ModernSelectField<String?>(
            label: 'Collaborateur',
            hint: 'Tous les collaborateurs',
            leadingIcon: Icons.person_search_rounded,
            allowClear: true,
            clearLabel: 'Tous les collaborateurs',
            value: selectedCollaborateurId ?? collabId,
            options: collaborateurs
                .map(
                  (c) => ModernSelectOption<String?>(
                    value: c.id,
                    label: c.fullName,
                    icon: Icons.person_rounded,
                  ),
                )
                .toList(),
            onChanged: onCollaborateurChanged!,
          ),
        ],
        const SizedBox(height: 16),
        _ObjectifCard(
          title: 'Objectifs réalisés — ${monthLabelFr(monthKey)}',
          done: done,
          total: total,
          pct: pct,
        ),
        const SizedBox(height: 12),
        _StatTile(
          icon: Icons.assignment_ind_outlined,
          label: 'Mon nombre de tâches assignées',
          value: '$asAssignee',
        ),
        const SizedBox(height: 8),
        _StatTile(
          icon: Icons.supervisor_account_outlined,
          label: 'Tâches assignées à superviseur',
          value: '$asSuperviseur',
        ),
        if (weeks.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Semaines du mois en cours',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...weeks.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'S${w.week}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AromaColors.zinc500,
                          ),
                        ),
                      ),
                      Text(
                        '${w.pct.toStringAsFixed(0)} %',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: w.pct / 100,
                      minHeight: 8,
                      backgroundColor: AromaColors.zinc100,
                      color: TaskUi.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecapHeader extends StatelessWidget {
  const _RecapHeader({
    required this.monthKey,
    required this.onPrev,
    required this.onNext,
  });

  final String monthKey;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon récapitulatif',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Objectifs et performance du mois',
          style: TextStyle(color: AromaColors.zinc500, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                monthLabelFr(monthKey),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ],
    );
  }
}

class _ObjectifCard extends StatelessWidget {
  const _ObjectifCard({
    required this.title,
    required this.done,
    required this.total,
    required this.pct,
  });

  final String title;
  final int done;
  final int total;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TaskUi.gradientStart.withValues(alpha: 0.12),
            TaskUi.gradientEnd.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TaskUi.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: TaskUi.accent,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '$done / $total terminées',
                  style: const TextStyle(color: AromaColors.zinc500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? pct / 100 : 0,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: TaskUi.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: TaskUi.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CollabRecapCard extends StatelessWidget {
  const _CollabRecapCard({
    required this.name,
    required this.done,
    required this.total,
    required this.pct,
    this.onTap,
  });

  final String name;
  final int done;
  final int total;
  final double pct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TaskUi.accent,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? pct / 100 : 0,
                    minHeight: 8,
                    backgroundColor: AromaColors.zinc100,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done / $total terminées',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc500,
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
