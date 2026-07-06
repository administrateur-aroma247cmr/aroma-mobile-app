import '../../models/intervention_rapport_draft.dart';
import '../../models/sortie_huile_diffuseur.dart';

InterventionRapportDraft applySortieHuileToDiffuseurs(
  InterventionRapportDraft draft,
  List<SortieHuileDiffuseur> sorties,
) {
  if (sorties.isEmpty) return draft;
  final byId = {for (final s in sorties) s.equipementId: s};
  return draft.copyWith(
    diffuseurs: draft.diffuseurs.map((d) {
      final s = byId[d.equipementId];
      if (s == null) return d;
      return d.copyWith(
        huileSenteur: s.senteur ?? s.huileLabel,
        huileDesignation: s.designation,
        quantiteMl: s.quantiteMl,
        sortieSource: s.source,
      );
    }).toList(),
  );
}

RapportDiffuseurDraft sortieHuileForEquipement(
  String equipementId,
  List<SortieHuileDiffuseur> sorties,
) {
  for (final s in sorties) {
    if (s.equipementId == equipementId) {
      return RapportDiffuseurDraft(
        equipementId: equipementId,
        label: '',
        huileSenteur: s.senteur ?? s.huileLabel,
        huileDesignation: s.designation,
        quantiteMl: s.quantiteMl,
        sortieSource: s.source,
      );
    }
  }
  return RapportDiffuseurDraft(equipementId: equipementId, label: '');
}
