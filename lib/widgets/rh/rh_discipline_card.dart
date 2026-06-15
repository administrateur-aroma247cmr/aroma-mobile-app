import 'package:flutter/material.dart';

import '../../models/discipline_rh.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'rh_ui.dart';

class RhDisciplineCard extends StatelessWidget {
  const RhDisciplineCard({
    super.key,
    required this.discipline,
    this.collaborateurName,
    required this.onTap,
  });

  final DisciplineRh discipline;
  final String? collaborateurName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = RhUi.statutDisciplineColors(discipline.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AromaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E4E7)),
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
                    color: colors.fg,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.fg.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                RhUi.typeDisciplineIcon(discipline.type),
                                size: 18,
                                color: colors.fg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    labelTypeDiscipline(discipline.type),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AromaColors.zinc900,
                                    ),
                                  ),
                                  if (collaborateurName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      collaborateurName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AromaColors.zinc500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            RhDisciplineStatusBadge(statut: discipline.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (discipline.motif != null &&
                            discipline.motif!.trim().isNotEmpty)
                          Text(
                            discipline.motif!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AromaColors.zinc800,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _Meta(
                              icon: Icons.calendar_today_outlined,
                              label: formatDateFr(discipline.date),
                            ),
                            _Meta(
                              icon: Icons.payments_outlined,
                              label: discipline.impactPaie
                                  ? 'Impact paie'
                                  : 'Sans impact paie',
                            ),
                            if (discipline.documents.isNotEmpty)
                              _Meta(
                                icon: Icons.attach_file_rounded,
                                label: '${discipline.documents.length} doc.',
                              ),
                          ],
                        ),
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

class RhDisciplineStatusBadge extends StatelessWidget {
  const RhDisciplineStatusBadge({super.key, required this.statut});

  final String? statut;

  @override
  Widget build(BuildContext context) {
    final colors = RhUi.statutDisciplineColors(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelStatutDiscipline(statut),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.fg,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AromaColors.zinc500),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
        ),
      ],
    );
  }
}
