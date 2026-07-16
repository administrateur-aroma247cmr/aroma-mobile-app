import 'dart:io';

import '../models/intervention_rapport_draft.dart';
import 'aroma_api.dart';

/// Upload progressif des photos de rapport vers la galerie CRM.
class InterventionRapportUploadService {
  InterventionRapportUploadService(this._api);

  final AromaApi _api;

  Future<RapportPhotoSlot> uploadSlotIfNeeded({
    required RapportPhotoSlot slot,
    required String folder,
  }) async {
    if (slot.galerieId != null && slot.galerieId!.isNotEmpty) {
      return slot;
    }
    final local = slot.localPath;
    if (local == null || local.isEmpty || !File(local).existsSync()) {
      return slot;
    }
    final uploaded = await _api.uploadGalerieToFolder([local], folder: folder);
    if (uploaded.isEmpty) return slot;
    final f = uploaded.first;
    // Garde localPath pour les vignettes (évite un re-download MinIO plein format).
    return RapportPhotoSlot(
      localPath: local,
      galerieId: f.id,
      galerieUrl: f.lienFichier,
      observation: slot.observation,
    );
  }

  Future<InterventionRapportDraft> ensureDraftUploaded({
    required InterventionRapportDraft draft,
    required String folder,
    void Function(String slotKey)? onSlotUploaded,
  }) async {
    final tech = await uploadSlotIfNeeded(
      slot: draft.technicienPhoto,
      folder: folder,
    );
    if (tech.galerieId != null) onSlotUploaded?.call('technicien');

    final diffuseurs = <RapportDiffuseurDraft>[];
    for (final d in draft.diffuseurs) {
      final photos = <String, RapportPhotoSlot>{};
      for (final e in d.photos.entries) {
        final uploaded = await uploadSlotIfNeeded(
          slot: e.value,
          folder: folder,
        );
        photos[e.key] = uploaded;
        if (uploaded.galerieId != null) {
          onSlotUploaded?.call('${d.equipementId}_${e.key}');
        }
      }
      diffuseurs.add(d.copyWith(photos: photos));
    }

    return draft.copyWith(
      technicienPhoto: tech,
      diffuseurs: diffuseurs,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  bool draftNeedsUpload(InterventionRapportDraft draft) {
    if (_slotNeedsUpload(draft.technicienPhoto)) return true;
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      for (final p in d.photos.values) {
        if (_slotNeedsUpload(p)) return true;
      }
    }
    return false;
  }

  bool _slotNeedsUpload(RapportPhotoSlot slot) {
    if (slot.galerieId != null && slot.galerieId!.isNotEmpty) return false;
    final local = slot.localPath;
    return local != null && local.isNotEmpty && File(local).existsSync();
  }

  Map<String, dynamic> buildSubmitPayload(InterventionRapportDraft draft) {
    final diffuseurs = <Map<String, dynamic>>[];
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      final photos = <String, String>{};
      for (final e in d.photos.entries) {
        final id = e.value.galerieId;
        if (id != null && id.isNotEmpty) photos[e.key] = id;
      }
      diffuseurs.add({
        'equipement_id': d.equipementId,
        'label': d.label,
        'traite': d.traite,
        'photos': photos,
        'values': d.values,
      });
    }
    final techId = draft.technicienPhoto.galerieId;
    if (techId == null || techId.isEmpty) {
      throw ApiException('Photo du technicien non envoyée.');
    }
    return {
      'technicien_photo_id': techId,
      'diffuseurs': diffuseurs,
    };
  }
}
