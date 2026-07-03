import '../models/intervention.dart';

/// Action principale sur une intervention en vue technicien terrain.
enum TechnicianInterventionAction { demarrer, creerRapport, none }

const _terminalEtats = {
  'Traité',
  'Effectué',
  'Rapport envoyé',
  "Rapport d'intervention",
  'Clos',
  'Terminé',
};

const _rapportEtats = {
  "Rapport d'intervention",
  'Rapport envoyé',
  'Traité',
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
  if (_rapportEtats.contains(e)) return TechnicianInterventionAction.none;
  if (e == 'Démarré' || e == "En attente rapport d'intervention") {
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
}) {
  switch (action) {
    case TechnicianInterventionAction.demarrer:
      return 'Démarrer';
    case TechnicianInterventionAction.creerRapport:
      return hasRapportDraft
          ? 'Continuer le rapport'
          : 'Créer le rapport';
    case TechnicianInterventionAction.none:
      return '';
  }
}
