import 'package:flutter/material.dart';

import '../../models/tache.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'task_ui.dart';

class TasksCalendarTab extends StatefulWidget {
  const TasksCalendarTab({
    super.key,
    required this.tasks,
    required this.showAllTasks,
    this.collaborateurId,
    required this.onTaskTap,
  });

  final List<Tache> tasks;
  final bool showAllTasks;
  final String? collaborateurId;
  final void Function(Tache) onTaskTap;

  @override
  State<TasksCalendarTab> createState() => _TasksCalendarTabState();
}

class _TasksCalendarTabState extends State<TasksCalendarTab> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  DateTime? _dueDate(Tache t) {
    final raw = t.dateButoire;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.length >= 10 ? raw : '$raw-01');
  }

  bool _forCollab(Tache t, String collabId) {
    final ids = t.collaborateurIds.isNotEmpty
        ? t.collaborateurIds
        : (t.collaborateurId != null ? [t.collaborateurId!] : <String>[]);
    return ids.contains(collabId) || t.superviseurId == collabId;
  }

  List<Tache> get _visibleTasks {
    if (widget.showAllTasks) return widget.tasks;
    final id = widget.collaborateurId;
    if (id == null) return const [];
    return widget.tasks.where((t) => _forCollab(t, id)).toList();
  }

  Map<int, List<Tache>> _tasksByDay(DateTime month) {
    final map = <int, List<Tache>>{};
    for (final t in _visibleTasks) {
      final d = _dueDate(t);
      if (d == null) continue;
      if (d.year != month.year || d.month != month.month) continue;
      map.putIfAbsent(d.day, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => (a.nomTache).compareTo(b.nomTache));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAllTasks && widget.collaborateurId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun profil collaborateur associé à ce compte : '
            'le calendrier ne peut pas s’afficher.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AromaColors.zinc500),
          ),
        ),
      );
    }

    final monthKey =
        '${_focusedMonth.year.toString().padLeft(4, '0')}-'
        '${_focusedMonth.month.toString().padLeft(2, '0')}';
    final byDay = _tasksByDay(_focusedMonth);
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Lundi = 1 … Dimanche = 7
    final startPad = first.weekday - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                monthLabelFr(monthKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            _WeekdayLabel('Lun'),
            _WeekdayLabel('Mar'),
            _WeekdayLabel('Mer'),
            _WeekdayLabel('Jeu'),
            _WeekdayLabel('Ven'),
            _WeekdayLabel('Sam'),
            _WeekdayLabel('Dim'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.72,
          ),
          itemCount: startPad + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startPad) {
              return const SizedBox.shrink();
            }
            final day = index - startPad + 1;
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isToday = _isSameDay(date, DateTime.now());
            final dayTasks = byDay[day] ?? const [];
            return _DayCell(
              day: day,
              isToday: isToday,
              tasks: dayTasks,
              onTaskTap: widget.onTaskTap,
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Tâches du mois (${byDay.values.fold<int>(0, (s, l) => s + l.length)})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...List.generate(daysInMonth, (i) {
          final day = i + 1;
          final list = byDay[day];
          if (list == null || list.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.toString().padLeft(2, '0')}/'
                  '${_focusedMonth.month.toString().padLeft(2, '0')} — '
                  '${list.length} tâche(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc800,
                  ),
                ),
                const SizedBox(height: 6),
                ...list.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _AgendaTile(tache: t, onTap: () => widget.onTaskTap(t)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc500,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.tasks,
    required this.onTaskTap,
  });

  final int day;
  final bool isToday;
  final List<Tache> tasks;
  final void Function(Tache) onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? TaskUi.accent.withValues(alpha: 0.08)
            : AromaColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? TaskUi.accent.withValues(alpha: 0.4) : const Color(0xFFE4E4E7),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isToday ? TaskUi.accent : AromaColors.zinc800,
            ),
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: tasks.length > 2 ? 2 : tasks.length,
                itemBuilder: (context, i) {
                  final t = tasks[i];
                  final overdue = TaskUi.isOverdue(t);
                  return GestureDetector(
                    onTap: () => onTaskTap(t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      decoration: BoxDecoration(
                        color: overdue
                            ? const Color(0xFFFEE2E2)
                            : TaskUi.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.nomTache,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: overdue
                              ? const Color(0xFFDC2626)
                              : TaskUi.accent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (tasks.length > 2)
              Text(
                '+${tasks.length - 2}',
                style: const TextStyle(fontSize: 8, color: AromaColors.zinc500),
              ),
          ],
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.tache, required this.onTap});

  final Tache tache;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = TaskUi.isOverdue(tache);
    return Material(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(
              tache.isTerminee ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: tache.isTerminee
                  ? const Color(0xFF059669)
                  : (overdue ? const Color(0xFFDC2626) : TaskUi.accent),
              size: 20,
            ),
            title: Text(
              tache.nomTache,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${tache.statut ?? 'En cours'} · ${formatDateFr(tache.dateButoire)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          ),
        ),
      ),
    );
  }
}
