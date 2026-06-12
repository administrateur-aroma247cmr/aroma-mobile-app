// Aligné sur le CRM web (`auth_roles.py` + `AuthContext.tsx`).

String _normRole(String? role) => (role ?? '').trim().toLowerCase();

bool isManagerRole(String? role) => _normRole(role) == 'manager';

bool isPrivilegedStaffRole(String? role) {
  final r = _normRole(role);
  return r == 'admin' ||
      r == 'ceo' ||
      r == 'manager' ||
      r == 'coordinateur' ||
      r == 'superviseur';
}

bool isExecutiveRole(String? role) {
  final r = _normRole(role);
  return r == 'admin' || r == 'ceo' || r == 'manager';
}

bool isCaisseMaPageDirectionRole(String? role) {
  final r = _normRole(role);
  return r == 'admin' ||
      r == 'ceo' ||
      r == 'manager' ||
      r == 'coordinateur';
}

bool canViewAllTachesRole(String? role) {
  final r = _normRole(role);
  return r == 'admin' ||
      r == 'ceo' ||
      r == 'manager' ||
      r == 'coordinateur';
}

bool canViewCollaborateurRecapsRole(String? role) {
  return _normRole(role) != 'coordinateur';
}

/// Lecture sur un service (droits collaborateur ou staff privilégié).
bool hasServiceAccess(
  Map<String, String> droits,
  String serviceId, {
  required bool privilegedStaff,
}) {
  if (privilegedStaff) return true;
  final level = droits[serviceId]?.trim().toLowerCase();
  return level == 'lecture' ||
      level == 'modification' ||
      level == 'suppression';
}

bool canModifyService(
  Map<String, String> droits,
  String serviceId, {
  required bool privilegedStaff,
}) {
  if (privilegedStaff) return true;
  final level = droits[serviceId]?.trim().toLowerCase();
  return level == 'modification' || level == 'suppression';
}

/// Modules ouverts à tous les utilisateurs authentifiés (comme HomePage web).
bool isOpenToAllModule(String moduleId) {
  return moduleId == 'tasks' ||
      moduleId == 'rh' ||
      moduleId == 'galerie' ||
      moduleId == 'caisse' ||
      moduleId == 'analytics';
}
