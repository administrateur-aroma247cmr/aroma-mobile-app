/// Action technicien terrain sur une intervention (sans création de rapport mobile).
enum TechnicianInterventionAction { demarrer, none }

const _terminalEtats = {
  'Traité',
  'Effectué',
  'Rapport envoyé',
  "Rapport d'intervention",
  'Clos',
  'Démarré',
  "En attente rapport d'intervention",
};

/// Détermine le bouton à afficher selon l'état courant.
TechnicianInterventionAction technicianInterventionAction(String? etat) {
  final e = (etat ?? '').trim();
  if (_terminalEtats.contains(e)) return TechnicianInterventionAction.none;
  if (e.isEmpty || e == 'Planifié' || e == 'En cours') {
    return TechnicianInterventionAction.demarrer;
  }
  return TechnicianInterventionAction.none;
}

String technicianInterventionActionLabel(TechnicianInterventionAction action) {
  switch (action) {
    case TechnicianInterventionAction.demarrer:
      return 'Démarrer';
    case TechnicianInterventionAction.none:
      return '';
  }
}
