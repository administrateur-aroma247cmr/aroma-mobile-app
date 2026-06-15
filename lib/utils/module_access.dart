// Règles d'accès modules — alignées sur le CRM web (HomePage, AuthContext, pages).

/// Visibilité tuile accueil (même logique que `HomePage.tsx`).
bool canShowHomeModuleTile(
  String moduleId, {
  required bool isPrivilegedStaff,
  required bool canAccessComptabilite,
  required bool canAccessInterventions,
}) {
  switch (moduleId) {
    case 'analytics':
    case 'tasks':
    case 'rh':
    case 'galerie':
    case 'caisse':
      return true;
    case 'interventions':
      return isPrivilegedStaff || canAccessInterventions;
    case 'validation':
      return isPrivilegedStaff;
    case 'compta':
      return isPrivilegedStaff || canAccessComptabilite;
    default:
      return false;
  }
}

bool canCreateTache({
  required bool isPrivilegedStaff,
  required bool canModifyTasks,
}) {
  return isPrivilegedStaff || canModifyTasks;
}

bool canDeleteTache({
  required bool isPrivilegedStaff,
}) {
  return isPrivilegedStaff;
}

bool canEditTacheContent({
  required bool isPrivilegedStaff,
  required bool canModifyTasks,
  required bool canViewAllTaches,
}) {
  return isPrivilegedStaff || canModifyTasks || canViewAllTaches;
}

bool canCreateCaisseDemande({
  required bool canModifyCaisse,
}) {
  return canModifyCaisse;
}

bool canAccessCaisseMaPage({
  required bool isCaisseMaPageDirection,
  required bool isDesignatedCaissier,
  required bool isDesignatedSuperviseurFermeture,
}) {
  return isCaisseMaPageDirection ||
      isDesignatedCaissier ||
      isDesignatedSuperviseurFermeture;
}

bool canValidateRhDemande({
  required bool isPrivilegedStaff,
}) {
  return isPrivilegedStaff;
}

bool canDeleteGalerieFile({
  required bool isExecutive,
  required bool isUploader,
}) {
  return isExecutive || isUploader;
}

bool canEditRecouvrement({
  required bool isPrivilegedStaff,
  required bool canAccessComptabilite,
  required bool canModifyComptabilite,
}) {
  return isPrivilegedStaff ||
      canModifyComptabilite ||
      canAccessComptabilite;
}

bool canViewRhExecutiveTabs({
  required bool isExecutive,
  required String? role,
}) {
  return isExecutive || role == 'coordinateur';
}
