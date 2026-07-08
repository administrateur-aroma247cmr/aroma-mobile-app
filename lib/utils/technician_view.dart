import '../models/intervention.dart';
import '../models/technicien.dart';
import '../providers/auth_provider.dart';

/// Vue terrain : flag explicite fiche RH (`/api/me` → est_technicien_terrain).
bool isTechnicianFieldView(AuthProvider auth) {
  if (auth.isPrivilegedStaff) return false;
  if (auth.hasEstTechnicienTerrainFlag) {
    return auth.estTechnicienTerrain;
  }
  // Backend pas encore déployé : repli sur le lien fiche technicien.
  return auth.technicienId != null;
}

/// Accès module interventions (staff privilégié ou droit service).
bool hasInterventionsModuleAccess(AuthProvider auth) {
  return auth.isPrivilegedStaff || auth.canAccess('interventions');
}

/// Liste interventions : filtre assignation technicien uniquement.
bool filterInterventionsByTechnicianAssignment(AuthProvider auth) {
  return isTechnicianFieldView(auth);
}

/// Filtre client après chargement API (secours si le backend ne filtre pas).
List<Intervention> filterInterventionsForTechnician(
  List<Intervention> rows,
  TechnicianMatchContext ctx, {
  required bool apiFilteredByTechnicien,
}) {
  if (apiFilteredByTechnicien) return rows;
  return rows
      .where((i) => isInterventionAssignedToTechnician(i, ctx))
      .toList();
}

String _normName(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Contexte pour associer une intervention au technicien connecté.
class TechnicianMatchContext {
  TechnicianMatchContext({
    required this.collaborateurId,
    this.technicienId,
    this.nameVariants = const [],
  });

  final String collaborateurId;
  final String? technicienId;
  final List<String> nameVariants;
}

Future<TechnicianMatchContext> buildTechnicianMatchContext(
  AuthProvider auth,
) async {
  final collabId = auth.collaborateurId;
  if (collabId == null) {
    throw StateError('collaborateur_id manquant');
  }

  final names = <String>{};
  String? technicienId = auth.technicienId;

  try {
    final collab = await auth.api.getCollaborateur(collabId);
    final full = _normName(collab.fullName);
    if (full.isNotEmpty) names.add(full);
    final last = _normName(collab.nom);
    if (last.isNotEmpty) names.add(last);
  } catch (_) {}

  try {
    final techs = await auth.api.listTechniciens();
    for (final t in techs) {
      if (t.idCollaborateur == collabId) {
        technicienId ??= t.id;
        final n = _normName(t.nom);
        if (n.isNotEmpty) names.add(n);
      }
    }
    technicienId ??= _technicienIdByName(techs, names);
  } catch (_) {}

  if (technicienId != null) {
    auth.cacheTechnicienId(technicienId);
  }

  return TechnicianMatchContext(
    collaborateurId: collabId,
    technicienId: technicienId,
    nameVariants: names.toList(),
  );
}

String? _technicienIdByName(List<Technicien> techs, Set<String> names) {
  if (names.isEmpty) return null;
  for (final t in techs) {
    final n = _normName(t.nom);
    if (n.isNotEmpty && names.contains(n)) return t.id;
  }
  return null;
}

bool isInterventionAssignedToTechnician(
  Intervention intervention,
  TechnicianMatchContext ctx,
) {
  final assignedId = (intervention.idTechnicien ?? '').trim();
  if (assignedId.isNotEmpty) {
    if (ctx.technicienId != null && assignedId == ctx.technicienId) {
      return true;
    }
    // Rétrocompat : certains enregistrements stockent l'id collaborateur.
    if (assignedId == ctx.collaborateurId) return true;
  }

  final techNom = _normName(intervention.technicienNom);
  if (techNom.isEmpty || ctx.nameVariants.isEmpty) return false;

  for (final variant in ctx.nameVariants) {
    if (variant.isEmpty) continue;
    if (techNom == variant) return true;
    if (techNom.contains(variant) || variant.contains(techNom)) return true;
  }
  return false;
}

/// Contexte technicien si l'utilisateur a une fiche collaborateur (sinon null).
Future<TechnicianMatchContext?> tryBuildTechnicianMatchContext(
  AuthProvider auth,
) async {
  if (auth.collaborateurId == null) return null;
  try {
    return await buildTechnicianMatchContext(auth);
  } catch (_) {
    return null;
  }
}

/// Démarrer / créer / continuer le rapport : réservé au technicien assigné.
bool canPerformTechnicianFieldActions(
  Intervention intervention,
  TechnicianMatchContext? ctx,
) {
  if (ctx == null) return false;
  return isInterventionAssignedToTechnician(intervention, ctx);
}

bool isReparationAssignedToTechnician(
  Reparation reparation,
  TechnicianMatchContext ctx,
) {
  final techNom = _normName(reparation.technicienNom);
  if (techNom.isEmpty || ctx.nameVariants.isEmpty) return false;
  for (final variant in ctx.nameVariants) {
    if (variant.isEmpty) continue;
    if (techNom == variant) return true;
    if (techNom.contains(variant) || variant.contains(techNom)) return true;
  }
  return false;
}

bool isTransportAssignedToTechnician(
  TransportIntervention transport,
  TechnicianMatchContext ctx,
) {
  final techNom = _normName(transport.technicienNom);
  if (techNom.isEmpty || ctx.nameVariants.isEmpty) return false;
  for (final variant in ctx.nameVariants) {
    if (variant.isEmpty) continue;
    if (techNom == variant) return true;
    if (techNom.contains(variant) || variant.contains(techNom)) return true;
  }
  return false;
}
