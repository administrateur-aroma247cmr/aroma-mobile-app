import 'package:flutter/material.dart';

import '../../models/demande_rh.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'rh_ui.dart';

class RhDemandeCard extends StatelessWidget {
  const RhDemandeCard({
    super.key,
    required this.demande,
    required this.canValidate,
    required this.onApprove,
    required this.onReject,
  });

  final DemandeRh demande;
  final bool canValidate;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = RhUi.statutColors(demande.statut);
    final pending = demande.statut == 'en_attente';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pending && canValidate
            ? () => _showActions(context)
            : null,
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
                                color: RhUi.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                RhUi.typeDemandeIcon(demande.type),
                                size: 18,
                                color: RhUi.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                labelTypeDemande(demande.type),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AromaColors.zinc900,
                                ),
                              ),
                            ),
                            RhStatusBadge(
                              label: labelStatutDemande(demande.statut),
                              statut: demande.statut,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.date_range_outlined,
                              size: 14,
                              color: AromaColors.zinc500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${formatDateFr(demande.dateDebut)} → ${formatDateFr(demande.dateFin)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AromaColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                        if (demande.motif != null &&
                            demande.motif!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            demande.motif!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AromaColors.zinc800,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (demande.montant != null && demande.montant! > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            fmtFcfa(demande.montant),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: RhUi.accent,
                            ),
                          ),
                        ],
                        if (pending && canValidate) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onReject,
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Rejeter'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFB91C1C),
                                    side: const BorderSide(
                                      color: Color(0xFFFECACA),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: onApprove,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Approuver'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
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

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                labelTypeDemande(demande.type),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onApprove();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approuver'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onReject();
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Rejeter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
