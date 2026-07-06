import 'package:flutter/material.dart';

import '../../models/materiel_sortie_ligne.dart';
import '../../theme/aroma_theme.dart';

/// Matériel réellement sorti pour l'intervention (lignes stock CRM).
class InterventionMaterielSortiCard extends StatelessWidget {
  const InterventionMaterielSortiCard({
    super.key,
    required this.lignes,
  });

  final List<MaterielSortieLigne> lignes;

  @override
  Widget build(BuildContext context) {
    if (lignes.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AromaColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AromaColors.zinc100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matériel sorti',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      Text(
                        'Sortie stock enregistrée',
                        style: TextStyle(
                          fontSize: 11,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: lignes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ligne = lignes[index];
              return _MaterielSortiRow(ligne: ligne);
            },
          ),
        ],
      ),
    );
  }
}

class _MaterielSortiRow extends StatelessWidget {
  const _MaterielSortiRow({required this.ligne});

  final MaterielSortieLigne ligne;

  @override
  Widget build(BuildContext context) {
    final ref = ligne.refAffiche;
    final senteur = (ligne.senteur ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AromaColors.zinc100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc900,
                  ),
                ),
                if (ref.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ref,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ],
                if (senteur.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Senteur : $senteur',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ligne.quantiteLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AromaColors.zinc900,
            ),
          ),
        ],
      ),
    );
  }
}
