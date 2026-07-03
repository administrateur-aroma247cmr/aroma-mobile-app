import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_client.dart';
import '../models/equipement_client.dart';
import '../models/intervention.dart';
import '../models/intervention_rapport_draft.dart';
import '../providers/auth_provider.dart';
import '../services/aroma_api.dart';
import '../services/intervention_rapport_store.dart';
import '../services/intervention_rapport_upload_service.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_evaluation_constants.dart';
import '../widgets/interventions/interventions_ui.dart';
import '../widgets/interventions/rapport_photo_slot.dart';
import '../widgets/interventions/rapport_retour_section.dart';

/// Création du rapport d’intervention — photos par critère (sans preview PDF).
class InterventionRapportScreen extends StatefulWidget {
  const InterventionRapportScreen({
    super.key,
    required this.interventionId,
    this.interventionSummary,
  });

  final String interventionId;
  final Intervention? interventionSummary;

  @override
  State<InterventionRapportScreen> createState() =>
      _InterventionRapportScreenState();
}

class _InterventionRapportScreenState extends State<InterventionRapportScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Intervention? _intervention;
  InterventionRapportDraft? _draft;
  List<ContactClient> _contacts = [];
  bool _loadingContacts = false;
  final _observationControllers = <String, TextEditingController>{};
  final _uploadingSlots = <String>{};
  Timer? _autoSaveTimer;
  InterventionRapportUploadService? _uploadService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final c in _observationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _rapportFolder(Intervention intervention) {
    final ref = (intervention.ref ?? intervention.id).replaceAll('/', '-');
    return 'Rapports/$ref';
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_persistDraftLocal(silent: true));
    });
  }

  Future<void> _persistDraftLocal({bool silent = false}) async {
    final draft = _draft;
    if (draft == null) return;
    try {
      await InterventionRapportStore.save(
        draft.copyWith(updatedAt: DateTime.now().toIso8601String()),
      );
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _uploadSlotInBackground({
    required String slotKey,
    required RapportPhotoSlot slot,
    required void Function(RapportPhotoSlot) onUpdated,
  }) async {
    final intervention = _intervention;
    final uploadService = _uploadService;
    if (intervention == null || uploadService == null) return;
    if (slot.galerieId != null && slot.galerieId!.isNotEmpty) return;
    final local = slot.localPath;
    if (local == null || local.isEmpty || !File(local).existsSync()) return;

    if (!mounted) return;
    setState(() => _uploadingSlots.add(slotKey));
    try {
      final uploaded = await uploadService.uploadSlotIfNeeded(
        slot: slot,
        folder: _rapportFolder(intervention),
      );
      if (!mounted) return;
      onUpdated(uploaded);
      final draft = _draft;
      if (draft != null) {
        await InterventionRapportStore.save(draft);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Envoi photo : $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingSlots.remove(slotKey));
      }
    }
  }

  TextEditingController _observationController(String key, String initial) {
    return _observationControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final intervention = widget.interventionSummary ??
          await api.getIntervention(widget.interventionId);
      final clientId = intervention.idClients;
      List<EquipementClient> equipements = [];
      if (clientId != null && clientId.isNotEmpty) {
        equipements = await api.listEquipements(clientId: clientId);
      }
      final siteId = intervention.idAgence;
      final siteEquipements = siteId != null && siteId.isNotEmpty
          ? equipements.where((e) => e.idAgence == siteId).toList()
          : equipements;
      siteEquipements.sort(
        (a, b) => buildDiffuseurEmplacementLabel(
          emplacement: a.emplacement,
          typeDiffuseur: a.typeDiffuseur,
          reference: a.reference,
        ).compareTo(
          buildDiffuseurEmplacementLabel(
            emplacement: b.emplacement,
            typeDiffuseur: b.typeDiffuseur,
            reference: b.reference,
          ),
        ),
      );

      final siteLabel = intervention.siteAffiche.isNotEmpty
          ? intervention.siteAffiche
          : (intervention.ville ?? 'Site');
      final emplacements = siteEquipements
          .map((e) => e.emplacement ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      final defaultLieux = buildDefaultRapportLieux(
        siteLabel: siteLabel,
        emplacements: emplacements,
      );

      List<ContactClient> contacts = [];
      if (clientId != null && clientId.isNotEmpty) {
        setState(() => _loadingContacts = true);
        try {
          final all = await api.listContacts(clientId: clientId);
          final siteId = intervention.idAgence;
          contacts = all
              .where(
                (c) =>
                    siteId == null ||
                    siteId.isEmpty ||
                    c.idAgence == null ||
                    c.idAgence!.isEmpty ||
                    c.idAgence == siteId,
              )
              .toList();
        } catch (_) {
          contacts = [];
        }
      }

      var draft = await InterventionRapportStore.load(widget.interventionId);
      if (draft == null) {
        draft = InterventionRapportDraft(
          interventionId: intervention.id,
          interventionRef: intervention.ref,
          lieux: defaultLieux,
          diffuseurs: siteEquipements
              .map(
                (e) => RapportDiffuseurDraft(
                  equipementId: e.id,
                  lieuKey: rapportLieuKeyForEmplacement(e.emplacement),
                  label: buildDiffuseurEmplacementLabel(
                    emplacement: e.emplacement,
                    typeDiffuseur: e.typeDiffuseur,
                    reference: e.reference,
                  ),
                  photos: {
                    for (final item in diffuseurCheckItems)
                      item.key: RapportPhotoSlot(),
                  },
                ),
              )
              .toList(),
        );
      } else {
        draft = _mergeLieux(draft, defaultLieux);
        draft = _mergeDiffuseurs(draft, siteEquipements);
      }

      if (!mounted) return;
      setState(() {
        _intervention = intervention;
        _draft = draft;
        _contacts = contacts;
        _loadingContacts = false;
        _loading = false;
        _uploadService = InterventionRapportUploadService(api);
      });
      _syncObservationControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  InterventionRapportDraft _mergeLieux(
    InterventionRapportDraft draft,
    List<RapportLieuDraft> defaults,
  ) {
    if (draft.lieux.isNotEmpty) {
      final existing = {for (final l in draft.lieux) l.lieuKey: l};
      final merged = <RapportLieuDraft>[];
      for (final d in defaults) {
        merged.add(existing[d.lieuKey] ?? d);
      }
      for (final l in draft.lieux) {
        if (!merged.any((m) => m.lieuKey == l.lieuKey)) {
          merged.add(l);
        }
      }
      return draft.copyWith(lieux: merged);
    }
    return draft.copyWith(lieux: defaults);
  }

  InterventionRapportDraft _mergeDiffuseurs(
    InterventionRapportDraft draft,
    List<EquipementClient> equipements,
  ) {
    final existing = {
      for (final d in draft.diffuseurs) d.equipementId: d,
    };
    final merged = <RapportDiffuseurDraft>[];
    for (final e in equipements) {
      final lieuKey = rapportLieuKeyForEmplacement(e.emplacement);
      final label = buildDiffuseurEmplacementLabel(
        emplacement: e.emplacement,
        typeDiffuseur: e.typeDiffuseur,
        reference: e.reference,
      );
      final prev = existing[e.id];
      if (prev != null) {
        merged.add(prev.copyWith(label: label, lieuKey: lieuKey));
        continue;
      }
      merged.add(
        RapportDiffuseurDraft(
          equipementId: e.id,
          lieuKey: lieuKey,
          label: label,
          photos: {
            for (final item in diffuseurCheckItems)
              item.key: RapportPhotoSlot(),
          },
        ),
      );
    }
    return draft.copyWith(diffuseurs: merged);
  }

  List<RapportDiffuseurDraft> _diffuseursForLieu(
    InterventionRapportDraft draft,
    String lieuKey,
  ) {
    return draft.diffuseurs
        .where((d) => (d.lieuKey ?? 'site') == lieuKey)
        .toList();
  }

  void _syncObservationControllers() {
    final draft = _draft;
    if (draft == null) return;
    for (final l in draft.lieux) {
      final key = l.lieuKey;
      final value = l.observation ?? '';
      final ctrl = _observationControllers[key];
      if (ctrl != null) {
        if (ctrl.text != value) ctrl.text = value;
      }
    }
  }

  void _setContactAccompagnant(RapportContactAccompagnant contact) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = draft.copyWith(contactAccompagnant: contact));
    _scheduleAutoSave();
  }

  void _setLieuDraft(String lieuKey, RapportLieuDraft lieu) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        lieux: draft.lieux
            .map((l) => l.lieuKey == lieuKey ? lieu : l)
            .toList(),
      );
    });
    _scheduleAutoSave();
  }

  void _setTechnicienPhoto(RapportPhotoSlot slot) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = draft.copyWith(technicienPhoto: slot));
    _scheduleAutoSave();
    unawaited(
      _uploadSlotInBackground(
        slotKey: 'technicien',
        slot: slot,
        onUpdated: (uploaded) {
          final d = _draft;
          if (d == null) return;
          setState(() => _draft = d.copyWith(technicienPhoto: uploaded));
        },
      ),
    );
  }

  void _setDiffuseurPhoto(
    String equipementId,
    String checkKey,
    RapportPhotoSlot slot,
  ) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          final photos = Map<String, RapportPhotoSlot>.from(d.photos);
          photos[checkKey] = slot;
          return d.copyWith(photos: photos);
        }).toList(),
      );
    });
    _scheduleAutoSave();
    unawaited(
      _uploadSlotInBackground(
        slotKey: '${equipementId}_$checkKey',
        slot: slot,
        onUpdated: (uploaded) {
          final d = _draft;
          if (d == null) return;
          setState(() {
            _draft = d.copyWith(
              diffuseurs: d.diffuseurs.map((diff) {
                if (diff.equipementId != equipementId) return diff;
                final photos = Map<String, RapportPhotoSlot>.from(diff.photos);
                photos[checkKey] = uploaded;
                return diff.copyWith(photos: photos);
              }).toList(),
            );
          });
        },
      ),
    );
  }

  List<String> _validationErrors() {
    final draft = _draft;
    if (draft == null) return ['Brouillon indisponible'];
    final errors = <String>[];
    if (!draft.technicienPhoto.hasPhoto) {
      errors.add('Photo du technicien requise');
    }
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      final label = d.label.trim().isNotEmpty ? d.label : 'Diffuseur';
      for (final item in diffuseurCheckItems) {
        final photo = d.photos[item.key];
        if (photo == null || !photo.hasPhoto) {
          errors.add('$label : ${item.label} — photo requise');
        }
      }
    }
    return errors;
  }

  String _buildRetourInterventionText(InterventionRapportDraft draft) {
    final blocks = <String>[];
    for (final l in draft.lieux) {
      final obs = (l.observation ?? '').trim();
      final parts = <String>[];
      if ((l.ressentiArriveeTechnicien ?? '').isNotEmpty) {
        parts.add('Arrivée tech: ${l.ressentiArriveeTechnicien}');
      }
      if ((l.ressentiDepartTechnicien ?? '').isNotEmpty) {
        parts.add('Départ tech: ${l.ressentiDepartTechnicien}');
      }
      if ((l.ressentiClient ?? '').isNotEmpty) {
        parts.add('Ressenti client: ${l.ressentiClient}');
      }
      if (obs.isNotEmpty || parts.isNotEmpty) {
        final header = '[${l.label}]';
        blocks.add(
          [
            header,
            if (parts.isNotEmpty) parts.join(' · '),
            if (obs.isNotEmpty) obs,
          ].join('\n'),
        );
      }
    }
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      final diffuseurLabel = d.label.trim().isNotEmpty ? d.label : 'Diffuseur';
      for (final item in diffuseurCheckItems) {
        final obs = (d.photos[item.key]?.observation ?? '').trim();
        if (obs.isNotEmpty) {
          blocks.add('[Photo — $diffuseurLabel — ${item.label}]\n$obs');
        }
      }
    }
    final techObs = (draft.technicienPhoto.observation ?? '').trim();
    if (techObs.isNotEmpty) {
      blocks.add('[Photo — Technicien]\n$techObs');
    }
    return blocks.join('\n\n');
  }

  String? _primaryRessentiTechnicien(InterventionRapportDraft draft) {
    return averageRessentiScale(
      draft.lieux.map((l) {
        final depart = (l.ressentiDepartTechnicien ?? '').trim();
        if (depart.isNotEmpty) return depart;
        return l.ressentiArriveeTechnicien;
      }),
    );
  }

  String? _primaryRessentiClient(InterventionRapportDraft draft) {
    return averageRessentiScale(
      draft.lieux.map((l) => l.ressentiClient),
    );
  }

  Future<String?> _persistContactAccompagnant(
    AromaApi api,
    Intervention intervention,
    RapportContactAccompagnant contact,
  ) async {
    final clientId = intervention.idClients;
    if (clientId == null || clientId.isEmpty) return null;
    if (!contact.hasContent) return null;
    if (!contact.isComplete) return null;

    final civilite = (contact.civilite ?? '').trim();
    final nom = (contact.nom ?? '').trim();
    final prenom = (contact.prenom ?? '').trim();
    final poste = (contact.poste ?? '').trim();
    final telephone = (contact.telephone ?? '').trim();

    if ((contact.contactId ?? '').isNotEmpty) {
      final updated = await api.updateContactClient(
        contact.contactId!,
        civilite: civilite,
        nom: nom,
        prenom: prenom,
        poste: poste,
        telephone: telephone,
      );
      return updated.id;
    }

    final created = await api.createContactClient(
      idTiers: clientId,
      idAgence: intervention.idAgence,
      civilite: civilite.isEmpty ? null : civilite,
      nom: nom,
      prenom: prenom.isEmpty ? null : prenom,
      poste: poste.isEmpty ? null : poste,
      telephone: telephone.isEmpty ? null : telephone,
    );
    return created.id;
  }

  Map<String, dynamic> _buildRapportTerrainBody(InterventionRapportDraft draft) {
    final techId = (draft.technicienPhoto.galerieId ?? '').trim();
    if (techId.isEmpty) {
      throw StateError('Photo du technicien non synchronisée — réessayez');
    }

    final diffuseurs = <Map<String, dynamic>>[];
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      final label = d.label.trim().isNotEmpty ? d.label : 'Diffuseur';
      final photos = <String, String>{};
      final photosObservations = <String, String>{};
      for (final item in diffuseurCheckItems) {
        final slot = d.photos[item.key];
        final galerieId = (slot?.galerieId ?? '').trim();
        if (galerieId.isEmpty) {
          throw StateError('$label : ${item.label} — photo non synchronisée');
        }
        photos[item.key] = galerieId;
        final obs = (slot?.observation ?? '').trim();
        if (obs.isNotEmpty) photosObservations[item.key] = obs;
      }
      diffuseurs.add({
        'equipement_id': d.equipementId,
        'label': label,
        'traite': true,
        'photos': photos,
        if (photosObservations.isNotEmpty)
          'photos_observations': photosObservations,
        if (d.values.isNotEmpty) 'values': d.values,
      });
    }

    final techObservation = (draft.technicienPhoto.observation ?? '').trim();

    return {
      'technicien_photo_id': techId,
      if (techObservation.isNotEmpty)
        'technicien_photo_observation': techObservation,
      'diffuseurs': diffuseurs,
    };
  }

  Future<void> _syncRetourToServer(
    AromaApi api,
    Intervention intervention,
    InterventionRapportDraft draft,
  ) async {
    final contactId = await _persistContactAccompagnant(
      api,
      intervention,
      draft.contactAccompagnant,
    );
    final ressentiClient = _primaryRessentiClient(draft);
    final ressentiTechnicien = _primaryRessentiTechnicien(draft);
    final body = <String, dynamic>{
      if (contactId != null) 'id_contact': contactId,
      if (ressentiClient != null) 'ressenti_client': ressentiClient,
      if (ressentiTechnicien != null) 'ressenti_technicien': ressentiTechnicien,
    };
    final retour = _buildRetourInterventionText(draft).trim();
    if (retour.isNotEmpty) {
      body['retour_intervention'] = retour;
    }
    if (body.isEmpty) return;
    await api.updateIntervention(intervention.id, body);
  }

  Future<void> _save({bool requireComplete = false}) async {
    final draft = _draft;
    final intervention = _intervention;
    if (draft == null || intervention == null) return;

    if (requireComplete) {
      if (_uploadingSlots.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envoi des photos en cours — patientez'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
      final errors = _validationErrors();
      if (errors.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.first),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final api = context.read<AuthProvider>().api;
      final ref = (intervention.ref ?? intervention.id).replaceAll('/', '-');
      final folder = 'Rapports/$ref';

      Future<RapportPhotoSlot> uploadSlot(RapportPhotoSlot slot) async {
        final local = slot.localPath;
        if (local == null || local.isEmpty || !File(local).existsSync()) {
          return slot;
        }
        final uploaded = await api.uploadGalerieToFolder(
          [local],
          folder: folder,
        );
        if (uploaded.isEmpty) return slot;
        final f = uploaded.first;
        return RapportPhotoSlot(
          galerieId: f.id,
          galerieUrl: f.lienFichier,
          observation: slot.observation,
        );
      }

      final techPhoto = await uploadSlot(draft.technicienPhoto);
      final diffuseurs = <RapportDiffuseurDraft>[];
      for (final d in draft.diffuseurs) {
        final photos = <String, RapportPhotoSlot>{};
        for (final e in d.photos.entries) {
          photos[e.key] = await uploadSlot(e.value);
        }
        diffuseurs.add(d.copyWith(photos: photos));
      }

      final saved = draft.copyWith(
        technicienPhoto: techPhoto,
        diffuseurs: diffuseurs,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await InterventionRapportStore.save(saved);

      if (requireComplete) {
        final terrainBody = _buildRapportTerrainBody(saved);
        await api.submitInterventionRapportTerrain(
          interventionId: intervention.id,
          body: terrainBody,
        );
        try {
          await _syncRetourToServer(api, intervention, saved);
        } catch (_) {
          // PDF + statut OK ; retour texte optionnel.
        }
      }

      if (!mounted) return;
      setState(() {
        _draft = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requireComplete
                ? 'Rapport envoyé (${saved.countPhotosFilled()} photos) — visible sur le web'
                : 'Brouillon enregistré',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      if (requireComplete) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final intervention = _intervention;
    final draft = _draft;

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Rapport d’intervention'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            TextButton(
              onPressed: draft == null ? null : () => _save(),
              child: const Text('Brouillon'),
            ),
            TextButton(
              onPressed: draft == null ? null : () => _save(requireComplete: true),
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? interventionsErrorState(message: _error!, onRetry: _load)
              : draft == null || intervention == null
                  ? const Center(child: Text('Données indisponibles'))
                  : _buildBody(intervention, draft),
    );
  }

  Widget _buildBody(Intervention intervention, InterventionRapportDraft draft) {
    final filled = draft.countPhotosFilled();
    final total = draft.countPhotosTotal();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: InterventionsUi.gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                intervention.ref ?? 'Intervention',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                intervention.clientNom ?? '—',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatDateFr(intervention.dateIntervention)} · ${intervention.siteAffiche.isNotEmpty ? intervention.siteAffiche : (intervention.ville ?? '—')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total > 0 ? filled / total : 0,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$filled / $total photos',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RapportContactAccompagnantSection(
          draft: draft.contactAccompagnant,
          contacts: _contacts,
          loadingContacts: _loadingContacts,
          hasClient:
              (intervention.idClients ?? '').trim().isNotEmpty,
          onChanged: _setContactAccompagnant,
        ),
        const SizedBox(height: 20),
        const Text(
          'Informations générales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AromaColors.zinc900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AromaColors.zinc200),
          ),
          child: RapportPhotoSlotWidget(
            compact: true,
            label: 'Photo du technicien',
            slot: draft.technicienPhoto,
            uploading: _uploadingSlots.contains('technicien'),
            onChanged: _setTechnicienPhoto,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Emplacements du site',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AromaColors.zinc900,
          ),
        ),
        const SizedBox(height: 10),
        if (draft.lieux.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AromaColors.zinc200),
              borderRadius: BorderRadius.circular(12),
              color: AromaColors.inputFill,
            ),
            child: const Text(
              'Aucun emplacement à renseigner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AromaColors.zinc500),
            ),
          )
        else
          ...draft.lieux.asMap().entries.map((entry) {
            final idx = entry.key;
            final l = entry.value;
            final diffuseurs = _diffuseursForLieu(draft, l.lieuKey);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RapportLieuBlocSection(
                index: idx + 1,
                lieu: l,
                diffuseurs: diffuseurs,
                uploadingSlots: _uploadingSlots,
                observationController: _observationController(
                  l.lieuKey,
                  l.observation ?? '',
                ),
                onLieuChanged: (next) => _setLieuDraft(l.lieuKey, next),
                onPhotoChanged: _setDiffuseurPhoto,
              ),
            );
          }),
        const SizedBox(height: 32),
      ],
    );
  }
}
