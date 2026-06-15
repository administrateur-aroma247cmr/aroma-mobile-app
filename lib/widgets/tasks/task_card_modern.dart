import 'package:flutter/material.dart';

import '../../models/tache.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'task_ui.dart';

class TaskCardModern extends StatelessWidget {
  const TaskCardModern({
    super.key,
    required this.tache,
    required this.client,
    required this.assignee,
    required this.superviseur,
    required this.onTap,
    required this.onToggleDone,
    required this.onToggleSelection,
  });

  final Tache tache;
  final String client;
  final String assignee;
  final String superviseur;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final overdue = TaskUi.isOverdue(tache);
    final priority = TaskUi.priorityColor(tache.priorite);
    final done = tache.isTerminee;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AromaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: overdue
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE4E4E7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: done ? AromaColors.zinc200 : priority,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DoneButton(
                              done: done,
                              onPressed: onToggleDone,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tache.nomTache,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AromaColors.zinc900,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AromaColors.zinc500,
                                    ),
                                  ),
                                  if ((tache.description ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tache.description!.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AromaColors.zinc500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: tache.isSelectionnee
                                  ? 'Retirer des sélectionnées'
                                  : 'Ajouter aux sélectionnées',
                              onPressed: onToggleSelection,
                              icon: Icon(
                                tache.isSelectionnee
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                color: tache.isSelectionnee
                                    ? TaskUi.accent
                                    : AromaColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            TaskMetaChip(
                              icon: Icons.flag_rounded,
                              label: tache.priorite ?? 'Moyenne',
                              tint: priority,
                            ),
                            TaskMetaChip(
                              icon: Icons.calendar_today_rounded,
                              label: formatDateFr(tache.dateButoire),
                              tint: overdue
                                  ? const Color(0xFFDC2626)
                                  : AromaColors.zinc500,
                            ),
                            if (tache.categorie != null &&
                                tache.categorie!.isNotEmpty)
                              TaskMetaChip(
                                icon: Icons.label_outline_rounded,
                                label: tache.categorie!,
                                tint: TaskUi.accent,
                              ),
                            if (overdue)
                              const TaskMetaChip(
                                icon: Icons.warning_amber_rounded,
                                label: 'En retard',
                                tint: Color(0xFFDC2626),
                              ),
                          ],
                        ),
                        if (client != '—' ||
                            assignee != '—' ||
                            superviseur != '—') ...[
                          const SizedBox(height: 10),
                          if (client != '—')
                            _PeopleRow(
                              icon: Icons.business_rounded,
                              label: client,
                            ),
                          if (assignee != '—')
                            _PeopleRow(
                              icon: Icons.person_outline_rounded,
                              label: assignee,
                              avatar: TaskUi.initials(assignee),
                            ),
                          if (superviseur != '—' &&
                              superviseur != assignee)
                            _PeopleRow(
                              icon: Icons.shield_outlined,
                              label: superviseur,
                            ),
                        ],
                      ],
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

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? const Color(0xFF059669) : Colors.transparent,
            border: Border.all(
              color: done ? const Color(0xFF059669) : AromaColors.zinc200,
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow({
    required this.icon,
    required this.label,
    this.avatar,
  });

  final IconData icon;
  final String label;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (avatar != null) ...[
            CircleAvatar(
              radius: 10,
              backgroundColor: TaskUi.accent.withValues(alpha: 0.15),
              child: Text(
                avatar!,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: TaskUi.accent,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ] else
            Icon(icon, size: 14, color: AromaColors.zinc500),
          if (avatar == null) const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AromaColors.zinc500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
