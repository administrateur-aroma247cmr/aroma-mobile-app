import 'package:flutter/material.dart';

import '../../models/contact_client.dart';
import '../../models/intervention_rapport_draft.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/intervention_evaluation_constants.dart';
import '../../utils/rapport_checklist.dart';
import 'interventions_ui.dart';
import 'rapport_photo_slot.dart';

enum _ContactMode { existing, newContact }

class RapportContactAccompagnantSection extends StatefulWidget {
  const RapportContactAccompagnantSection({
    super.key,
    required this.draft,
    required this.contacts,
    required this.loadingContacts,
    required this.hasClient,
    required this.onChanged,
  });

  final RapportContactAccompagnant draft;
  final List<ContactClient> contacts;
  final bool loadingContacts;
  final bool hasClient;
  final ValueChanged<RapportContactAccompagnant> onChanged;

  @override
  State<RapportContactAccompagnantSection> createState() =>
      _RapportContactAccompagnantSectionState();
}

class _RapportContactAccompagnantSectionState
    extends State<RapportContactAccompagnantSection> {
  late _ContactMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = (widget.draft.contactId ?? '').isNotEmpty
        ? _ContactMode.existing
        : _ContactMode.newContact;
  }

  @override
  void didUpdateWidget(RapportContactAccompagnantSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.draft.contactId ?? '').isNotEmpty &&
        oldWidget.draft.contactId != widget.draft.contactId) {
      _mode = _ContactMode.existing;
    }
  }

  void _switchMode(_ContactMode mode) {
    setState(() => _mode = mode);
    if (mode == _ContactMode.newContact) {
      widget.onChanged(
        RapportContactAccompagnant().copyWith(clearContactId: true),
      );
    } else {
      widget.onChanged(RapportContactAccompagnant());
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AromaColors.zinc200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Personne accompagnante',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AromaColors.zinc900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personne rencontrée sur site.',
            style: TextStyle(fontSize: 12, color: AromaColors.zinc500),
          ),
          if (widget.hasClient) ...[
            const SizedBox(height: 12),
            _ContactModeTabs(
              mode: _mode,
              onModeChanged: _switchMode,
            ),
          ],
          const SizedBox(height: 12),
          if (!widget.hasClient) ...[
            const Text(
              'Client non lié : saisie manuelle uniquement.',
              style: TextStyle(fontSize: 13, color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 10),
            ..._newContactFields(draft),
          ] else if (widget.loadingContacts)
            const Text(
              'Chargement des contacts…',
              style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
            )
          else if (_mode == _ContactMode.existing)
            _existingContactPicker(draft)
          else
            ..._newContactFields(draft),
        ],
      ),
    );
  }

  Widget _existingContactPicker(RapportContactAccompagnant draft) {
    final selectedId =
        (draft.contactId ?? '').isNotEmpty ? draft.contactId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.contacts.isEmpty)
          const Text(
            'Aucun contact enregistré. Utilisez « Nouveau contact ».',
            style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            decoration: _fieldDecoration(hint: '— Sélectionner —'),
            items: widget.contacts
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      c.listeLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              final c = widget.contacts.firstWhere((x) => x.id == id);
              widget.onChanged(
                RapportContactAccompagnant(
                  contactId: c.id,
                  civilite: c.civilite,
                  nom: c.nom,
                  prenom: c.prenom,
                  poste: c.poste,
                  telephone: c.telephone,
                ),
              );
            },
          ),
        if (selectedId != null) ...[
          const SizedBox(height: 10),
          _SelectedContactSummary(draft: draft),
        ],
      ],
    );
  }

  List<Widget> _newContactFields(RapportContactAccompagnant draft) {
    return [
      DropdownButtonFormField<String>(
        initialValue: contactCiviliteOptions.contains(draft.civilite ?? '')
            ? (draft.civilite ?? '')
            : '',
        isExpanded: true,
        decoration: _fieldDecoration(label: 'Civilité'),
        items: contactCiviliteOptions
            .map(
              (v) => DropdownMenuItem<String>(
                value: v,
                child: Text(v.isEmpty ? '—' : v),
              ),
            )
            .toList(),
        onChanged: (v) => widget.onChanged(draft.copyWith(civilite: v ?? '')),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _RapportTextField(
              label: 'Prénom',
              value: draft.prenom ?? '',
              onChanged: (v) => widget.onChanged(draft.copyWith(prenom: v)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RapportTextField(
              label: 'Nom *',
              value: draft.nom ?? '',
              onChanged: (v) => widget.onChanged(draft.copyWith(nom: v)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _RapportTextField(
        label: 'Poste',
        value: draft.poste ?? '',
        onChanged: (v) => widget.onChanged(draft.copyWith(poste: v)),
      ),
      const SizedBox(height: 10),
      _RapportTextField(
        label: 'Téléphone',
        value: draft.telephone ?? '',
        keyboardType: TextInputType.phone,
        onChanged: (v) => widget.onChanged(draft.copyWith(telephone: v)),
      ),
    ];
  }
}

class _ContactModeTabs extends StatelessWidget {
  const _ContactModeTabs({
    required this.mode,
    required this.onModeChanged,
  });

  final _ContactMode mode;
  final ValueChanged<_ContactMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AromaColors.zinc200),
        borderRadius: BorderRadius.circular(10),
        color: AromaColors.inputFill,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ContactModeTab(
              label: 'Ancien contact',
              selected: mode == _ContactMode.existing,
              onTap: () => onModeChanged(_ContactMode.existing),
            ),
          ),
          Expanded(
            child: _ContactModeTab(
              label: 'Nouveau contact',
              selected: mode == _ContactMode.newContact,
              onTap: () => onModeChanged(_ContactMode.newContact),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactModeTab extends StatelessWidget {
  const _ContactModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AromaColors.zinc900 : AromaColors.zinc500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedContactSummary extends StatelessWidget {
  const _SelectedContactSummary({required this.draft});

  final RapportContactAccompagnant draft;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      [
        (draft.civilite ?? '').trim(),
        (draft.prenom ?? '').trim(),
        (draft.nom ?? '').trim(),
      ].where((p) => p.isNotEmpty).join(' '),
      if ((draft.poste ?? '').trim().isNotEmpty) draft.poste!.trim(),
      if ((draft.telephone ?? '').trim().isNotEmpty) draft.telephone!.trim(),
    ].where((p) => p.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Text(
        parts.isEmpty ? '—' : parts.join(' · '),
        style: const TextStyle(fontSize: 13, color: AromaColors.zinc800),
      ),
    );
  }
}

/// Bloc lieu : ressenti + observations + photos diffuseurs du même emplacement.
class RapportLieuBlocSection extends StatelessWidget {
  const RapportLieuBlocSection({
    super.key,
    required this.index,
    required this.lieu,
    required this.diffuseurs,
    required this.checklist,
    required this.uploadingSlots,
    required this.observationController,
    required this.onLieuChanged,
    required this.onPhotoChanged,
    required this.onTraiteChanged,
    required this.onValueChanged,
    required this.onAddAction,
    required this.onAddExtra,
    required this.onRemoveExtra,
  });

  final int index;
  final RapportLieuDraft lieu;
  final List<RapportDiffuseurDraft> diffuseurs;
  final List<RapportCheckItem> checklist;
  final Set<String> uploadingSlots;
  final TextEditingController observationController;
  final ValueChanged<RapportLieuDraft> onLieuChanged;
  final void Function(String equipementId, String checkKey, RapportPhotoSlot slot)
      onPhotoChanged;
  final void Function(String equipementId, bool traite) onTraiteChanged;
  final void Function(String equipementId, String key, String value)
      onValueChanged;
  final void Function(String equipementId) onAddAction;
  final void Function(String equipementId) onAddExtra;
  final void Function(String equipementId, String key) onRemoveExtra;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AromaColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AromaColors.zinc200, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emplacement $index',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        lieu.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: RapportLieuRessentiFields(
              draft: lieu,
              observationController: observationController,
              onChanged: onLieuChanged,
            ),
          ),
          if (diffuseurs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (var i = 0; i < diffuseurs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _DiffuseurPhotosBlock(
                      index: i + 1,
                      draft: diffuseurs[i],
                      checklist: checklist,
                      uploadingSlots: uploadingSlots,
                      onPhotoChanged: (key, slot) => onPhotoChanged(
                        diffuseurs[i].equipementId,
                        key,
                        slot,
                      ),
                      onTraiteChanged: (traite) => onTraiteChanged(
                        diffuseurs[i].equipementId,
                        traite,
                      ),
                      onValueChanged: (key, value) => onValueChanged(
                        diffuseurs[i].equipementId,
                        key,
                        value,
                      ),
                      onAddAction: () => onAddAction(diffuseurs[i].equipementId),
                      onAddExtra: () => onAddExtra(diffuseurs[i].equipementId),
                      onRemoveExtra: (key) =>
                          onRemoveExtra(diffuseurs[i].equipementId, key),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RapportLieuRessentiFields extends StatelessWidget {
  const RapportLieuRessentiFields({
    super.key,
    required this.draft,
    required this.observationController,
    required this.onChanged,
  });

  final RapportLieuDraft draft;
  final TextEditingController observationController;
  final ValueChanged<RapportLieuDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AromaColors.zinc200.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RessentiCompactPicker(
            caption: 'Arrivée',
            label: 'Technicien',
            value: draft.ressentiArriveeTechnicien ?? '',
            onChanged: (v) =>
                onChanged(draft.copyWith(ressentiArriveeTechnicien: v)),
          ),
          const SizedBox(height: 8),
          _RessentiCompactPicker(
            caption: 'Départ',
            label: 'Technicien',
            value: draft.ressentiDepartTechnicien ?? '',
            onChanged: (v) =>
                onChanged(draft.copyWith(ressentiDepartTechnicien: v)),
          ),
          const SizedBox(height: 8),
          _RessentiCompactPicker(
            caption: 'Départ',
            label: 'Client',
            value: draft.ressentiClient ?? '',
            onChanged: (v) => onChanged(draft.copyWith(ressentiClient: v)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: observationController,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontSize: 13),
            decoration: _fieldDecoration(
              label: 'Observations',
              hint: 'Optionnel',
              dense: true,
            ),
            onChanged: (v) => onChanged(draft.copyWith(observation: v)),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur 0–10 compact (chips horizontaux).
class _RessentiCompactPicker extends StatelessWidget {
  const _RessentiCompactPicker({
    required this.caption,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String caption;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected =
        ressentiInterventionOptions.contains(value) ? value : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$caption · $label',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AromaColors.zinc500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ressentiInterventionOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final v = ressentiInterventionOptions[i];
              final isSelected = selected == v;
              final display = v.isEmpty ? '—' : v;
              return Material(
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onChanged(v),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0EA5E9)
                            : AromaColors.zinc200,
                      ),
                    ),
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AromaColors.zinc800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiffuseurPhotosBlock extends StatefulWidget {
  const _DiffuseurPhotosBlock({
    required this.index,
    required this.draft,
    required this.checklist,
    required this.uploadingSlots,
    required this.onPhotoChanged,
    required this.onTraiteChanged,
    required this.onValueChanged,
    required this.onAddAction,
    required this.onAddExtra,
    required this.onRemoveExtra,
  });

  final int index;
  final RapportDiffuseurDraft draft;
  final List<RapportCheckItem> checklist;
  final Set<String> uploadingSlots;
  final void Function(String checkKey, RapportPhotoSlot slot) onPhotoChanged;
  final ValueChanged<bool> onTraiteChanged;
  final void Function(String key, String value) onValueChanged;
  final VoidCallback onAddAction;
  final VoidCallback onAddExtra;
  final void Function(String key) onRemoveExtra;

  @override
  State<_DiffuseurPhotosBlock> createState() => _DiffuseurPhotosBlockState();
}

class _DiffuseurPhotosBlockState extends State<_DiffuseurPhotosBlock> {
  bool _expanded = true;

  bool get _hasSortieHuile =>
      (widget.draft.quantiteMl ?? 0) > 0 ||
      (widget.draft.huileSenteur ?? '').trim().isNotEmpty;

  String get _sortieHuileLabel {
    final huile = (widget.draft.huileSenteur ??
            widget.draft.huileDesignation ??
            '')
        .trim();
    final qte = widget.draft.quantiteMl;
    if (huile.isEmpty && qte == null) return '';
    final qteLabel = qte == null
        ? ''
        : ' — ${qte % 1 == 0 ? qte.toInt() : qte.toStringAsFixed(1)} ml';
    return 'Huile : $huile$qteLabel';
  }

  List<String> get _actionKeys =>
      actionKeysSorted(widget.draft.photos.keys);

  List<String> get _extraKeys => extraKeysSorted(widget.draft.photos.keys);

  List<RapportCheckItem> get _fixedItems => fixedChecklistItems(widget.checklist)
      .where((i) => i.key != extraKey)
      .toList();

  int get _filledCount {
    if (!widget.draft.traite) return 0;
    var n = 0;
    for (final item in _fixedItems) {
      final slot = widget.draft.photos[item.key];
      if (slot != null && slot.hasPhoto) n++;
    }
    for (final key in _actionKeys) {
      final slot = widget.draft.photos[key];
      if (slot != null && slot.hasPhoto) n++;
    }
    return n;
  }

  int get _totalCount {
    if (!widget.draft.traite) return 0;
    var n = requiredPhotoItems(widget.checklist).length;
    if (checklistHasRepeatableActions(widget.checklist)) {
      n += _actionKeys.isEmpty ? 1 : _actionKeys.length;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final traite = widget.draft.traite;
    final filled = _filledCount;
    final total = _totalCount;
    final progress = total > 0 ? filled / total : 0.0;
    final hasExtras = checklistHasRepeatableExtras(widget.checklist);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: traite ? const Color(0xFFF8FAFC) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: traite ? AromaColors.zinc200 : AromaColors.zinc200.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diffuseur ${widget.index}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: traite
                              ? const Color(0xFF6366F1)
                              : AromaColors.zinc500,
                        ),
                      ),
                      Text(
                        widget.draft.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: traite
                              ? AromaColors.zinc900
                              : AromaColors.zinc500,
                        ),
                      ),
                      if (_hasSortieHuile) ...[
                        const SizedBox(height: 4),
                        Text(
                          _sortieHuileLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: traite
                                ? const Color(0xFF4F46E5)
                                : AromaColors.zinc400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (traite) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$filled/$total',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AromaColors.zinc800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 36,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AromaColors.zinc200,
                            color: filled == total
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: _TraiteSegment(
              traite: traite,
              onChanged: widget.onTraiteChanged,
            ),
          ),
          if (traite && _expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: RapportPhotoCompactList(
                children: [
                  for (final item in _fixedItems) ...[
                      RapportPhotoSlotWidget(
                        compact: true,
                        label: item.label,
                        slot: widget.draft.photos[item.key] ?? RapportPhotoSlot(),
                        uploading: widget.uploadingSlots.contains(
                          '${widget.draft.equipementId}_${item.key}',
                        ),
                        onChanged: (s) => widget.onPhotoChanged(item.key, s),
                      ),
                      if (item.numeric) ...[
                        const SizedBox(height: 4),
                        _NumericValueField(
                          label: item.numericPlaceholder ?? 'Poids (g)',
                          value: widget.draft.values[item.key] ?? '',
                          onChanged: (v) =>
                              widget.onValueChanged(item.key, v),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ],
                  if (checklistHasRepeatableActions(widget.checklist)) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Actions réalisées',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final key in _actionKeys)
                      RapportPhotoSlotWidget(
                        compact: true,
                        label: actionLabelForKey(key),
                        slot: widget.draft.photos[key] ?? RapportPhotoSlot(),
                        uploading: widget.uploadingSlots.contains(
                          '${widget.draft.equipementId}_$key',
                        ),
                        onChanged: (s) => widget.onPhotoChanged(key, s),
                      ),
                    _RapportAddBlockButton(
                      label: 'Ajouter une action',
                      icon: Icons.construction_outlined,
                      onPressed: widget.onAddAction,
                    ),
                  ],
                  if (hasExtras) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Photos supplémentaires',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final key in _extraKeys)
                      RapportPhotoSlotWidget(
                        compact: true,
                        label: extraLabelForKey(key),
                        slot: widget.draft.photos[key] ?? RapportPhotoSlot(),
                        uploading: widget.uploadingSlots.contains(
                          '${widget.draft.equipementId}_$key',
                        ),
                        onChanged: (s) => widget.onPhotoChanged(key, s),
                        onRemoveBlock: () => widget.onRemoveExtra(key),
                      ),
                    _RapportAddBlockButton(
                      label: 'Ajouter une photo supplémentaire',
                      icon: Icons.add_photo_alternate_outlined,
                      onPressed: widget.onAddExtra,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RapportAddBlockButton extends StatelessWidget {
  const _RapportAddBlockButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: InterventionsUi.accentMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: InterventionsUi.accent.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: InterventionsUi.accentSoft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: InterventionsUi.accent.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: InterventionsUi.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: InterventionsUi.accent,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: InterventionsUi.accent.withValues(alpha: 0.75),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TraiteSegment extends StatelessWidget {
  const _TraiteSegment({
    required this.traite,
    required this.onChanged,
  });

  final bool traite;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AromaColors.zinc200),
        borderRadius: BorderRadius.circular(10),
        color: AromaColors.inputFill,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TraiteSegmentTab(
              label: 'Traité',
              icon: Icons.check_circle_outline_rounded,
              selected: traite,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TraiteSegmentTab(
              label: 'Non traité',
              icon: Icons.remove_circle_outline_rounded,
              selected: !traite,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraiteSegmentTab extends StatelessWidget {
  const _TraiteSegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? const Color(0xFF0EA5E9)
                    : AromaColors.zinc500,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AromaColors.zinc900 : AromaColors.zinc500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericValueField extends StatelessWidget {
  const _NumericValueField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('num_$label$value'),
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: _fieldDecoration(label: label, dense: true),
      onChanged: onChanged,
    );
  }
}

class _RapportTextField extends StatefulWidget {
  const _RapportTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<_RapportTextField> createState() => _RapportTextFieldState();
}

class _RapportTextFieldState extends State<_RapportTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_RapportTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: _fieldDecoration(label: widget.label),
      onChanged: widget.onChanged,
    );
  }
}

InputDecoration _fieldDecoration({
  String? label,
  String? hint,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(fontSize: 12),
    isDense: dense,
    filled: true,
    fillColor: AromaColors.inputFill,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 10,
      vertical: dense ? 8 : 10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AromaColors.zinc200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AromaColors.zinc200),
    ),
  );
}
