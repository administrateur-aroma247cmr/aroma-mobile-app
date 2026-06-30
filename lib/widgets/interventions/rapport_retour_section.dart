import 'package:flutter/material.dart';

import '../../models/contact_client.dart';
import '../../models/intervention_rapport_draft.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/intervention_evaluation_constants.dart';
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
    required this.uploadingSlots,
    required this.observationController,
    required this.onLieuChanged,
    required this.onPhotoChanged,
  });

  final int index;
  final RapportLieuDraft lieu;
  final List<RapportDiffuseurDraft> diffuseurs;
  final Set<String> uploadingSlots;
  final TextEditingController observationController;
  final ValueChanged<RapportLieuDraft> onLieuChanged;
  final void Function(String equipementId, String checkKey, RapportPhotoSlot slot)
      onPhotoChanged;

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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emplacement $index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                Text(
                  lieu.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: RapportLieuRessentiFields(
              draft: lieu,
              observationController: observationController,
              onChanged: onLieuChanged,
            ),
          ),
          if (diffuseurs.isNotEmpty) ...[
            const Divider(height: 1, color: AromaColors.zinc200),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                'Diffuseurs (${diffuseurs.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AromaColors.zinc800,
                ),
              ),
            ),
            ...diffuseurs.asMap().entries.map((entry) {
              final dIdx = entry.key;
              final d = entry.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _DiffuseurPhotosBlock(
                  index: dIdx + 1,
                  draft: d,
                  uploadingSlots: uploadingSlots,
                  onPhotoChanged: (key, slot) =>
                      onPhotoChanged(d.equipementId, key, slot),
                ),
              );
            }),
          ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RessentiCompactPicker(
                  caption: 'Départ',
                  label: 'Technicien',
                  value: draft.ressentiDepartTechnicien ?? '',
                  onChanged: (v) =>
                      onChanged(draft.copyWith(ressentiDepartTechnicien: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RessentiCompactPicker(
                  caption: 'Départ',
                  label: 'Client',
                  value: draft.ressentiClient ?? '',
                  onChanged: (v) => onChanged(draft.copyWith(ressentiClient: v)),
                ),
              ),
            ],
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
            separatorBuilder: (_, __) => const SizedBox(width: 4),
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

class _DiffuseurPhotosBlock extends StatelessWidget {
  const _DiffuseurPhotosBlock({
    required this.index,
    required this.draft,
    required this.uploadingSlots,
    required this.onPhotoChanged,
  });

  final int index;
  final RapportDiffuseurDraft draft;
  final Set<String> uploadingSlots;
  final void Function(String checkKey, RapportPhotoSlot slot) onPhotoChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          RapportPhotoSlotsGrid(
            children: [
              for (final item in diffuseurCheckItems)
                RapportPhotoSlotWidget(
                  gridTile: true,
                  label: item.label,
                  slot: draft.photos[item.key] ?? RapportPhotoSlot(),
                  uploading: uploadingSlots.contains(
                    '${draft.equipementId}_${item.key}',
                  ),
                  onChanged: (s) => onPhotoChanged(item.key, s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RapportTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: _fieldDecoration(label: label),
      onChanged: onChanged,
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
