import '../models/intervention.dart';

/// Action principale sur une intervention (terrain + staff interventions).
enum TechnicianInterventionAction { demarrer, creerRapport, none }

const _terminalEtats = {
  'Traité',
  'Effectué',
  'Rapport envoyé',
  "Rapport d'intervention",
  'Clos',
  'Terminé',
};

/// Plus de modification possible (rapport définitivement envoyé ou clôturé).
const _lockedEtats = {
  'Rapport envoyé',
  'Effectué',
  'Clos',
  'Terminé',
};

const _technicianHiddenEtats = {
  "Rapport d'intervention",
  'Rapport envoyé',
};

/// État affiché au technicien : masque les états CRM internes rapport.
String? interventionEtatForTechnicianDisplay(Intervention intervention) {
  final e = (intervention.etatAfficheTechnicien ?? '').trim();
  if (e.isEmpty) return null;
  if (_technicianHiddenEtats.contains(e)) return 'Traité';
  return e;
}

/// Détermine le bouton à afficher selon l'état courant (CRM).
TechnicianInterventionAction technicianInterventionAction(String? etat) {
  final e = (etat ?? '').trim();
  if (_lockedEtats.contains(e)) return TechnicianInterventionAction.none;
  if (e == 'Démarré' ||
      e == "En attente rapport d'intervention" ||
      e == "Rapport d'intervention" ||
      e == 'Traité') {
    return TechnicianInterventionAction.creerRapport;
  }
  if (e.isEmpty || e == 'Planifié' || e == 'En cours') {
    return TechnicianInterventionAction.demarrer;
  }
  if (!_terminalEtats.contains(e)) {
    return TechnicianInterventionAction.demarrer;
  }
  return TechnicianInterventionAction.none;
}

String technicianInterventionActionLabel(
  TechnicianInterventionAction action, {
  bool hasRapportDraft = false,
  String? etat,
}) {
  switch (action) {
    case TechnicianInterventionAction.demarrer:
      return 'Démarrer';
    case TechnicianInterventionAction.creerRapport:
      final e = (etat ?? '').trim();
      if (hasRapportDraft ||
          e == "Rapport d'intervention" ||
          e == "En attente rapport d'intervention" ||
          e == 'Traité') {
        return 'Continuer le rapport';
      }
      return 'Créer le rapport';
    case TechnicianInterventionAction.none:
      return '';
  }
}
