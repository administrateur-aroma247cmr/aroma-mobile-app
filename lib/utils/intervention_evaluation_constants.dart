// Aligné sur crm/frontend/src/lib/interventionEvaluation.ts

class DiffuseurCheckItemDef {
  const DiffuseurCheckItemDef({
    required this.key,
    required this.label,
    this.numeric = false,
    this.numericPlaceholder,
  });

  final String key;
  final String label;
  final bool numeric;
  final String? numericPlaceholder;
}

const diffuseurCheckItems = <DiffuseurCheckItemDef>[
  DiffuseurCheckItemDef(
    key: 'nettoyage_alcool',
    label: 'Nettoyage à l’alcool',
  ),
  DiffuseurCheckItemDef(
    key: 'position',
    label: 'Photo grand angle — positionnement du diffuseur',
  ),
  DiffuseurCheckItemDef(
    key: 'reservoir_ouvert',
    label: 'Photo diffuseur — réservoir ouvert (huile restante)',
  ),
  DiffuseurCheckItemDef(
    key: 'pesee_etat',
    label: 'Photo pesée bouteille en l’état',
    numeric: true,
    numericPlaceholder: 'Poids (g)',
  ),
  DiffuseurCheckItemDef(
    key: 'pesee_recharge',
    label: 'Photo pesée avec la recharge (poids mis en avant)',
    numeric: true,
    numericPlaceholder: 'Poids (g)',
  ),
  DiffuseurCheckItemDef(
    key: 'programmation',
    label: 'Photo programmation ou programmation écrite',
  ),
  DiffuseurCheckItemDef(
    key: 'reservoir_plein',
    label: 'Photo réservoir plein dans l’appareil',
  ),
  DiffuseurCheckItemDef(
    key: 'ferme',
    label: 'Photo diffuseur fermé et remis à sa place',
  ),
];

const contactCiviliteOptions = <String>['', 'M.', 'Mme', 'Mlle'];

/// Échelle 0–10 (alignée fiche ADC / retour intervention web).
const ressentiInterventionOptions = <String>[
  '',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
];

String ressentiInterventionLabel(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '—';
  return v;
}

String buildDiffuseurEmplacementLabel({
  String? emplacement,
  String? typeDiffuseur,
  String? reference,
}) {
  final parts = [emplacement, typeDiffuseur, reference]
      .map((s) => (s ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return parts.isNotEmpty ? parts.join(' — ') : '—';
}
