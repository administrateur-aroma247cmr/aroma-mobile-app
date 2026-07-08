import '../models/intervention_rapport_draft.dart';
import 'aroma_api.dart';
import 'intervention_rapport_store.dart';

/// Sync brouillon rapport terrain vers le backend (garde-fou mise à jour app).
/// Échec réseau = silencieux ; le flux local reste inchangé.
class InterventionRapportDraftSync {
  InterventionRapportDraftSync._();

  static Future<void> pushRemote({
    required AromaApi api,
    required InterventionRapportDraft draft,
  }) async {
    try {
      await api.putInterventionRapportTerrainDraft(
        interventionId: draft.interventionId,
        payload: draft.toJson(),
      );
    } catch (_) {
      // Non bloquant.
    }
  }

  static Future<void> deleteRemote({
    required AromaApi api,
    required String interventionId,
  }) async {
    try {
      await api.deleteInterventionRapportTerrainDraft(interventionId);
    } catch (_) {
      // Non bloquant.
    }
  }

  /// Fusionne brouillon local et serveur (le plus récent ``updated_at`` gagne).
  static Future<InterventionRapportDraft?> mergeWithRemote({
    required AromaApi api,
    required String interventionId,
    InterventionRapportDraft? local,
  }) async {
    try {
      final remote = await api.getInterventionRapportTerrainDraft(interventionId);
      if (remote == null) return local;
      final remoteDraft = InterventionRapportDraft.fromJson(remote);
      if (local == null) {
        await InterventionRapportStore.save(remoteDraft);
        return remoteDraft;
      }
      final localTs = DateTime.tryParse(local.updatedAt ?? '');
      final remoteTs = DateTime.tryParse(remoteDraft.updatedAt ?? '');
      if (remoteTs != null &&
          (localTs == null || !localTs.isAfter(remoteTs))) {
        await InterventionRapportStore.save(remoteDraft);
        return remoteDraft;
      }
      return local;
    } catch (_) {
      return local;
    }
  }
}
