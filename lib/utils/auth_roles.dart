/// Aligné sur le CRM web (`is_privileged_staff` / `UserRoleEnum`).
bool isPrivilegedStaffRole(String? role) {
  final r = (role ?? '').trim().toLowerCase();
  return r == 'admin' ||
      r == 'ceo' ||
      r == 'coordinateur' ||
      r == 'superviseur';
}
