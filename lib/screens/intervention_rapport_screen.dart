import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipement_client.dart';
import '../models/intervention.dart';
import '../models/intervention_rapport_draft.dart';
import '../providers/auth_provider.dart';
import '../services/intervention_rapport_store.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_evaluation_constants.dart';
import '../widgets/interventions/interventions_ui.dart';
import '../widgets/interventions/rapport_photo_slot.dart';

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
  final _peseeControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _peseeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _peseeController(String key, String initial) {
    return _peseeControllers.putIfAbsent(
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

      var draft = await InterventionRapportStore.load(widget.interventionId);
      if (draft == null) {
        draft = InterventionRapportDraft(
          interventionId: intervention.id,
          interventionRef: intervention.ref,
          diffuseurs: siteEquipements
              .map(
                (e) => RapportDiffuseurDraft(
                  equipementId: e.id,
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
        draft = _mergeDiffuseurs(draft, siteEquipements);
      }

      if (!mounted) return;
      setState(() {
        _intervention = intervention;
        _draft = draft;
        _loading = false;
      });
      _syncPeseeControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
      final prev = existing[e.id];
      if (prev != null) {
        merged.add(prev);
        continue;
      }
      merged.add(
        RapportDiffuseurDraft(
          equipementId: e.id,
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
      );
    }
    return draft.copyWith(diffuseurs: merged);
  }

  void _syncPeseeControllers() {
    final draft = _draft;
    if (draft == null) return;
    for (final d in draft.diffuseurs) {
      for (final item in diffuseurCheckItems) {
        if (!item.numeric) continue;
        final key = '${d.equipementId}_${item.key}';
        final value = d.values[item.key] ?? '';
        final ctrl = _peseeControllers[key];
        if (ctrl != null) {
          if (ctrl.text != value) ctrl.text = value;
        }
      }
    }
  }

  void _setTechnicienPhoto(RapportPhotoSlot slot) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = draft.copyWith(technicienPhoto: slot));
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
  }

  void _setPeseeValue(String equipementId, String checkKey, String value) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        diffuseurs: draft.diffuseurs.map((d) {
          if (d.equipementId != equipementId) return d;
          final values = Map<String, String>.from(d.values);
          values[checkKey] = value;
          return d.copyWith(values: values);
        }).toList(),
      );
    });
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
        if (item.numeric) {
          final raw = (d.values[item.key] ?? '').trim();
          if (raw.isEmpty) {
            errors.add('$label : ${item.label} — poids requis');
          } else {
            final n = double.tryParse(raw.replaceAll(',', '.'));
            if (n == null || n < 0) {
              errors.add('$label : ${item.label} — poids invalide');
            }
          }
        }
      }
    }
    return errors;
  }

  Future<void> _save({bool requireComplete = false}) async {
    final draft = _draft;
    final intervention = _intervention;
    if (draft == null || intervention == null) return;

    if (requireComplete) {
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

      if (!mounted) return;
      setState(() {
        _draft = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requireComplete
                ? 'Rapport enregistré (${saved.countPhotosFilled()} photos)'
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
        const Text(
          'Informations générales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AromaColors.zinc900,
          ),
        ),
        const SizedBox(height: 10),
        RapportPhotoSlotsGrid(
          children: [
            RapportPhotoSlotWidget(
              gridTile: true,
              label: 'Photo du technicien',
              slot: draft.technicienPhoto,
              onChanged: _setTechnicienPhoto,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Diffuseurs du site',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AromaColors.zinc900,
          ),
        ),
        const SizedBox(height: 10),
        if (draft.diffuseurs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AromaColors.zinc200),
              borderRadius: BorderRadius.circular(12),
              color: AromaColors.inputFill,
            ),
            child: const Text(
              'Aucun diffuseur trouvé pour ce site.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AromaColors.zinc500),
            ),
          )
        else
          ...draft.diffuseurs.asMap().entries.map((entry) {
            final idx = entry.key;
            final d = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DiffuseurSection(
                index: idx + 1,
                draft: d,
                peseeController: _peseeController,
                onPhotoChanged: (key, slot) =>
                    _setDiffuseurPhoto(d.equipementId, key, slot),
                onPeseeChanged: (key, value) =>
                    _setPeseeValue(d.equipementId, key, value),
              ),
            );
          }),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DiffuseurSection extends StatelessWidget {
  const _DiffuseurSection({
    required this.index,
    required this.draft,
    required this.peseeController,
    required this.onPhotoChanged,
    required this.onPeseeChanged,
  });

  final int index;
  final RapportDiffuseurDraft draft;
  final TextEditingController Function(String key, String initial) peseeController;
  final void Function(String checkKey, RapportPhotoSlot slot) onPhotoChanged;
  final void Function(String checkKey, String value) onPeseeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diffuseur $index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                Text(
                  draft.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: RapportPhotoSlotsGrid(
              children: [
                for (final item in diffuseurCheckItems)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RapportPhotoSlotWidget(
                        gridTile: true,
                        label: item.label,
                        slot: draft.photos[item.key] ?? RapportPhotoSlot(),
                        onChanged: (s) => onPhotoChanged(item.key, s),
                      ),
                      if (item.numeric) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: peseeController(
                            '${draft.equipementId}_${item.key}',
                            draft.values[item.key] ?? '',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: item.numericPlaceholder ?? 'Poids (g)',
                            labelStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            filled: true,
                            fillColor: AromaColors.inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (v) => onPeseeChanged(item.key, v),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
