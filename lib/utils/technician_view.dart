import '../models/intervention.dart';
import '../models/technicien.dart';
import '../providers/auth_provider.dart';

/// Vue terrain technicien : collaborateur connecté, hors staff privilégié.
bool isTechnicianFieldView(AuthProvider auth) {
  return !auth.isPrivilegedStaff && auth.collaborateurId != null;
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

/// Plage large pour la vue terrain (sans sélecteur de mois).
({String from, String to}) technicianInterventionDateRange() {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month - 12, 1);
  final to = DateTime(now.year, now.month + 3, 0);
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return (from: fmt(from), to: fmt(to));
}
