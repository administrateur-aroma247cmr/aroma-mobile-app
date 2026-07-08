import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_client.dart';
import '../models/equipement_client.dart';
import '../models/intervention.dart';
import '../models/intervention_rapport_draft.dart';
import '../models/sortie_huile_diffuseur.dart';
import '../providers/auth_provider.dart';
import '../services/aroma_api.dart';
import '../services/intervention_rapport_draft_sync.dart';
import '../services/intervention_rapport_store.dart';
import '../services/intervention_rapport_upload_service.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_evaluation_constants.dart';
import '../utils/rapport_checklist.dart';
import '../utils/sortie_huile_diffuseur_merge.dart';
import '../utils/technician_view.dart';
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

  List<RapportCheckItem> get _checklist =>
      diffuseurChecklistForType(_intervention?.typeIntervention);

  Map<String, RapportPhotoSlot> _initialPhotosMap({
    required String? typeIntervention,
    Map<String, RapportPhotoSlot>? existing,
  }) {
    final checklist = diffuseurChecklistForType(typeIntervention);
    final merged = <String, RapportPhotoSlot>{};
    for (final item in fixedChecklistItems(checklist)) {
      merged[item.key] = existing?[item.key] ?? RapportPhotoSlot();
    }
    if (existing != null) {
      for (final e in existing.entries) {
        if (isActionKey(e.key) || isExtraKey(e.key)) {
          merged[e.key] = e.value;
        }
      }
    }
    if (checklistHasRepeatableActions(checklist) &&
        !merged.keys.any(isActionKey)) {
      merged['action_1'] = RapportPhotoSlot();
    }
    return merged;
  }

  int _countPhotosFilled(InterventionRapportDraft draft) {
    var n = draft.technicienPhoto.hasPhoto ? 1 : 0;
    final checklist = _checklist;
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      for (final item in requiredPhotoItems(checklist)) {
        if (d.photos[item.key]?.hasPhoto == true) n++;
      }
      if (checklistHasRepeatableActions(checklist)) {
        for (final key in actionKeysSorted(d.photos.keys)) {
          if (d.photos[key]?.hasPhoto == true) n++;
        }
      }
    }
    return n;
  }

  int _countPhotosTotal(InterventionRapportDraft draft) {
    var n = 1;
    final checklist = _checklist;
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      n += requiredPhotoItems(checklist).length;
      if (checklistHasRepeatableActions(checklist)) {
        final actions = actionKeysSorted(d.photos.keys);
        n += actions.isEmpty ? 1 : actions.length;
      }
    }
    return n;
  }

  String _formatMl(double qte) {
    final s = qte % 1 == 0 ? qte.toInt().toString() : qte.toStringAsFixed(1);
    return '$s ml';
  }

  String? _headerSortieHuileLabel(Intervention intervention) {
    final Iterable<String> labels;
    final double totalMl;

    if (intervention.showHuileTotale &&
        intervention.sortieHuileTotale.isNotEmpty) {
      final items = intervention.sortieHuileTotale
          .where((s) => s.quantiteMl > 0)
          .toList();
      if (items.isEmpty) return null;
      labels = items.map((s) => s.label);
      totalMl = items.fold<double>(0, (sum, s) => sum + s.quantiteMl);
    } else if (intervention.showHuileParDiffuseur &&
        intervention.sortieHuileParDiffuseur.isNotEmpty) {
      final items = intervention.sortieHuileParDiffuseur
          .where((s) => s.quantiteMl > 0)
          .toList();
      if (items.isEmpty) return null;
      labels = items.map((s) => s.huileLabel);
      totalMl = items.fold<double>(0, (sum, s) => sum + s.quantiteMl);
    } else {
      return null;
    }

    final senteurs = <String>[];
    final seen = <String>{};
    for (final label in labels) {
      final t = label.trim();
      if (t.isEmpty || t == 'Huile') continue;
      if (seen.add(t)) senteurs.add(t);
    }
    final senteurPart =
        senteurs.isEmpty ? 'Huile' : senteurs.join(', ');
    return '$senteurPart · ${_formatMl(totalMl)}';
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
      final saved = draft.copyWith(updatedAt: DateTime.now().toIso8601String());
      await InterventionRapportStore.save(saved);
      if (mounted) {
        final api = context.read<AuthProvider>().api;
        unawaited(
          InterventionRapportDraftSync.pushRemote(api: api, draft: saved),
        );
      }
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
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      // Toujours recharger l’intervention : le résumé liste peut omettre sortie_huile_*.
      final intervention = await api.getIntervention(widget.interventionId);
      final matchCtx = await tryBuildTechnicianMatchContext(auth);
      if (!canPerformTechnicianFieldActions(intervention, matchCtx)) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error =
              'Action réservée au technicien assigné à cette intervention.';
        });
        return;
      }
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

      var draft = await InterventionRapportDraftSync.mergeWithRemote(
        api: api,
        interventionId: widget.interventionId,
        local: await InterventionRapportStore.load(widget.interventionId),
      );
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
                  photos: _initialPhotosMap(
                    typeIntervention: intervention.typeIntervention,
                  ),
                ),
              )
              .toList(),
        );
      } else {
        draft = _mergeLieux(draft, defaultLieux);
        draft = _mergeDiffuseurs(
          draft,
          siteEquipements,
          intervention.typeIntervention,
          intervention.showHuileParDiffuseur
              ? intervention.sortieHuileParDiffuseur
              : const [],
        );
      }
      draft = applySortieHuileToDiffuseurs(
        draft,
        intervention.showHuileParDiffuseur
            ? intervention.sortieHuileParDiffuseur
            : const [],
      );

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
    String? typeIntervention,
    List<SortieHuileDiffuseur> sorties,
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
        merged.add(
          prev.copyWith(
            label: label,
            lieuKey: lieuKey,
            photos: _initialPhotosMap(
              typeIntervention: typeIntervention,
              existing: prev.photos,
            ),
          ),
        );
        continue;
      }
      final sortie = sortieHuileForEquipement(e.id, sorties);
      merged.add(
        RapportDiffuseurDraft(
          equipementId: e.id,
          lieuKey: lieuKey,
          label: label,
          huileSenteur: sortie.huileSenteur,
          huileDesignation: sortie.huileDesignation,
          quantiteMl: sortie.quantiteMl,
          sortieSource: sortie.sortieSource,
          photos: _initialPhotosMap(typeIntervention: typeIntervention),
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

  void _setDiffuseurTraite(String equipementId, bool traite) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          return d.copyWith(traite: traite);
        }).toList(),
      );
    });
    _scheduleAutoSave();
  }

  void _addDiffuseurAction(String equipementId) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          final photos = Map<String, RapportPhotoSlot>.from(d.photos);
          final key = nextActionKey(photos.keys);
          photos[key] = RapportPhotoSlot();
          return d.copyWith(photos: photos);
        }).toList(),
      );
    });
    _scheduleAutoSave();
  }

  void _addDiffuseurExtra(String equipementId) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          final photos = Map<String, RapportPhotoSlot>.from(d.photos);
          final key = nextExtraKey(photos.keys);
          photos[key] = RapportPhotoSlot();
          return d.copyWith(photos: photos);
        }).toList(),
      );
    });
    _scheduleAutoSave();
  }

  void _removeDiffuseurExtra(String equipementId, String key) {
    if (!isExtraKey(key)) return;
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          final photos = Map<String, RapportPhotoSlot>.from(d.photos);
          photos.remove(key);
          return d.copyWith(photos: photos);
        }).toList(),
      );
    });
    _uploadingSlots.remove('${equipementId}_$key');
    _scheduleAutoSave();
  }

  List<String> _validationErrors() {
    final draft = _draft;
    if (draft == null) return ['Brouillon indisponible'];
    final errors = <String>[];
    if (!draft.technicienPhoto.hasPhoto) {
      errors.add('Photo du technicien requise');
    }
    final treated = draft.diffuseurs.where((d) => d.traite).toList();
    if (treated.isEmpty) {
      errors.add('Au moins un diffuseur traité est requis');
    }
    final checklist = _checklist;
    for (final d in treated) {
      final label = d.label.trim().isNotEmpty ? d.label : 'Diffuseur';
      for (final item in requiredPhotoItems(checklist)) {
        final photo = d.photos[item.key];
        if (photo == null || !photo.hasPhoto) {
          errors.add('$label : ${item.label} — photo requise');
        }
      }
      if (checklistHasRepeatableActions(checklist)) {
        final hasAction = actionKeysSorted(d.photos.keys)
            .any((k) => d.photos[k]?.hasPhoto == true);
        if (!hasAction) {
          errors.add(
            '$label : Photos des actions réalisées — au moins une photo requise',
          );
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
      final checklist = _checklist;
      for (final item in fixedChecklistItems(checklist)) {
        final obs = (d.photos[item.key]?.observation ?? '').trim();
        if (obs.isNotEmpty) {
          blocks.add('[Photo — $diffuseurLabel — ${item.label}]\n$obs');
        }
      }
      for (final key in actionKeysSorted(d.photos.keys)) {
        final obs = (d.photos[key]?.observation ?? '').trim();
        if (obs.isNotEmpty) {
          blocks.add(
            '[Photo — $diffuseurLabel — ${actionLabelForKey(key)}]\n$obs',
          );
        }
      }
      for (final key in extraKeysSorted(d.photos.keys)) {
        final obs = (d.photos[key]?.observation ?? '').trim();
        if (obs.isNotEmpty) {
          blocks.add(
            '[Photo — $diffuseurLabel — ${extraLabelForKey(key)}]\n$obs',
          );
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

    final checklist = _checklist;
    final diffuseurs = <Map<String, dynamic>>[];
    for (final d in draft.diffuseurs) {
      if (!d.traite) continue;
      final label = d.label.trim().isNotEmpty ? d.label : 'Diffuseur';
      final photos = <String, String>{};
      final photosObservations = <String, String>{};

      void addPhotoKey(String key) {
        final slot = d.photos[key];
        final galerieId = (slot?.galerieId ?? '').trim();
        if (galerieId.isEmpty) return;
        photos[key] = galerieId;
        final obs = (slot?.observation ?? '').trim();
        if (obs.isNotEmpty) photosObservations[key] = obs;
      }

      for (final item in requiredPhotoItems(checklist)) {
        final slot = d.photos[item.key];
        final galerieId = (slot?.galerieId ?? '').trim();
        if (galerieId.isEmpty) {
          throw StateError('$label : ${item.label} — photo non synchronisée');
        }
        addPhotoKey(item.key);
      }
      if (checklistHasRepeatableActions(checklist)) {
        final actionKeys = actionKeysSorted(d.photos.keys)
            .where((k) => d.photos[k]?.hasPhoto == true);
        if (actionKeys.isEmpty) {
          throw StateError(
            '$label : Photos des actions réalisées — au moins une photo requise',
          );
        }
        for (final key in actionKeys) {
          addPhotoKey(key);
        }
      }
      for (final key in extraKeysSorted(d.photos.keys)) {
        if (d.photos[key]?.hasPhoto == true) {
          addPhotoKey(key);
        }
      }

      diffuseurs.add({
        'equipement_id': d.equipementId,
        'label': label,
        'traite': true,
        'photos': photos,
        if ((d.lieuKey ?? '').trim().isNotEmpty) 'lieu_key': d.lieuKey!.trim(),
        if (photosObservations.isNotEmpty)
          'photos_observations': photosObservations,
        if (d.values.isNotEmpty) 'values': d.values,
      });
    }

    final lieux = draft.lieux.map((l) => l.toJson()).toList();
    final techObservation = (draft.technicienPhoto.observation ?? '').trim();

    return {
      'technicien_photo_id': techId,
      if (techObservation.isNotEmpty)
        'technicien_photo_observation': techObservation,
      if (lieux.isNotEmpty) 'lieux': lieux,
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
      unawaited(
        InterventionRapportDraftSync.pushRemote(api: api, draft: saved),
      );

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
        // Brouillon serveur : supprimé uniquement côté API au POST /rapport-terrain
        // (évite un double DELETE + double audit).
        await InterventionRapportStore.delete(intervention.id);
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
                ? 'Rapport envoyé (${_countPhotosFilled(saved)} photos) — visible sur le web'
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
    final filled = _countPhotosFilled(draft);
    final total = _countPhotosTotal(draft);
    final huileHeader = _headerSortieHuileLabel(intervention);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      intervention.ref ?? 'Intervention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (huileHeader != null) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        huileHeader,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total > 0 ? filled / total : 0,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                checklist: _checklist,
                uploadingSlots: _uploadingSlots,
                observationController: _observationController(
                  l.lieuKey,
                  l.observation ?? '',
                ),
                onLieuChanged: (next) => _setLieuDraft(l.lieuKey, next),
                onPhotoChanged: _setDiffuseurPhoto,
                onTraiteChanged: _setDiffuseurTraite,
                onAddAction: _addDiffuseurAction,
                onAddExtra: _addDiffuseurExtra,
                onRemoveExtra: _removeDiffuseurExtra,
              ),
            );
          }),
        const SizedBox(height: 32),
      ],
    );
  }
}
