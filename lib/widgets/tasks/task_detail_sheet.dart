import 'package:flutter/material.dart';

import '../../models/tache.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'task_ui.dart';

Future<void> showTaskDetailSheet(
  BuildContext context, {
  required Tache tache,
  required String client,
  required String assignee,
  required String superviseur,
  required bool canEdit,
  required bool canDelete,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onToggleDone,
  required VoidCallback onToggleSelection,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TaskDetailSheet(
      tache: tache,
      client: client,
      assignee: assignee,
      superviseur: superviseur,
      canEdit: canEdit,
      canDelete: canDelete,
      onEdit: onEdit,
      onDelete: onDelete,
      onToggleDone: onToggleDone,
      onToggleSelection: onToggleSelection,
    ),
  );
}

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.tache,
    required this.client,
    required this.assignee,
    required this.superviseur,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDone,
    required this.onToggleSelection,
  });

  final Tache tache;
  final String client;
  final String assignee;
  final String superviseur;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final overdue = TaskUi.isOverdue(tache);
    final priority = TaskUi.priorityColor(tache.priorite);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AromaColors.zinc200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priority.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tache.priorite ?? 'Moyenne',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: priority,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (overdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'En retard',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onToggleSelection();
                          },
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
                    Text(
                      tache.nomTache,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    if ((tache.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        tache.description!.trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AromaColors.zinc500,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _DetailTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date butoire',
                      value: formatDateFr(tache.dateButoire),
                    ),
                    if (tache.categorie != null && tache.categorie!.isNotEmpty)
                      _DetailTile(
                        icon: Icons.label_outline_rounded,
                        label: 'Catégorie',
                        value: tache.categorie!,
                      ),
                    _DetailTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Statut',
                      value: tache.statut ?? 'En cours',
                    ),
                    if (client != '—')
                      _DetailTile(
                        icon: Icons.business_rounded,
                        label: 'Client',
                        value: client,
                      ),
                    if (assignee != '—')
                      _DetailTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Assigné à',
                        value: assignee,
                      ),
                    if (superviseur != '—')
                      _DetailTile(
                        icon: Icons.shield_outlined,
                        label: 'Superviseur',
                        value: superviseur,
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onToggleDone();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: tache.isTerminee
                            ? AromaColors.zinc800
                            : const Color(0xFF059669),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        tache.isTerminee
                            ? Icons.replay_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      label: Text(
                        tache.isTerminee
                            ? 'Rouvrir la tâche'
                            : 'Marquer comme terminée',
                      ),
                    ),
                    if (canEdit || canDelete) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (canEdit)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onEdit();
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Modifier'),
                              ),
                            ),
                          if (canEdit && canDelete)
                            const SizedBox(width: 12),
                          if (canDelete)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(
                                    color: Color(0xFFFECACA),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Supprimer'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AromaColors.zinc500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
