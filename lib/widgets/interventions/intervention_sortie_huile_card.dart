import 'package:flutter/material.dart';

import '../../models/sortie_huile_diffuseur.dart';
import '../../models/sortie_huile_totale.dart';
import '../../theme/aroma_theme.dart';

/// Huile sortie — mode total (par senteur) ou par diffuseur (aligné CRM).
class InterventionSortieHuileCard extends StatelessWidget {
  const InterventionSortieHuileCard({
    super.key,
    this.mode,
    this.totale = const [],
    this.parDiffuseur = const [],
  });

  final String? mode;
  final List<SortieHuileTotale> totale;
  final List<SortieHuileDiffuseur> parDiffuseur;

  bool get _isTotal => mode == 'total' && totale.isNotEmpty;
  bool get _isParDiffuseur =>
      (mode == 'diffuseur' || mode == 'contractuel') && parDiffuseur.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_isTotal && !_isParDiffuseur) return const SizedBox.shrink();

    final title = _isTotal ? 'Huile sortie (totale)' : 'Huile par diffuseur';
    final subtitle = _isTotal
        ? 'Quantités par senteur'
        : mode == 'contractuel'
            ? 'Estimation contractuelle'
            : 'Quantité par appareil';

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
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
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
            itemCount: _isTotal ? totale.length : parDiffuseur.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (_isTotal) {
                return _SortieHuileTotaleRow(item: totale[index]);
              }
              return _SortieHuileDiffuseurRow(item: parDiffuseur[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _SortieHuileTotaleRow extends StatelessWidget {
  const _SortieHuileTotaleRow({required this.item});

  final SortieHuileTotale item;

  @override
  Widget build(BuildContext context) {
    final ref = (item.refJpc ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AromaColors.zinc100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
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
              ],
            ),
          ),
          Text(
            _formatMl(item.quantiteMl),
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

class _SortieHuileDiffuseurRow extends StatelessWidget {
  const _SortieHuileDiffuseurRow({required this.item});

  final SortieHuileDiffuseur item;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = item.sourceLabel;
    final sourceColor = item.isManuel
        ? const Color(0xFF0EA5E9)
        : item.isSortieReelle
            ? const Color(0xFF16A34A)
            : const Color(0xFF8B5CF6);

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
                  item.diffuseurLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.huileLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMl(item.quantiteMl),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AromaColors.zinc900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sourceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: sourceColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatMl(double qte) {
  final s = qte % 1 == 0 ? qte.toInt().toString() : qte.toStringAsFixed(1);
  return '$s ml';
}
