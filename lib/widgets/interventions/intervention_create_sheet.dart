import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agence_client.dart';
import '../../models/client_lite.dart';
import '../../models/intervention_prospect_cible.dart';
import '../../models/technicien.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../modern_bottom_sheet.dart';
import '../modern_select_field.dart';
import 'interventions_ui.dart';

const _typesClient = <({String id, String label})>[
  (id: 'VT', label: 'VT'),
  (id: 'QC', label: 'QC'),
  (id: 'VDC', label: 'VDC'),
  (id: 'MT', label: 'MT'),
  (id: 'Refill', label: 'Refill'),
  (id: 'Installations', label: 'Installations'),
];

const _typesProspect = <({String id, String label})>[
  (id: 'VT', label: 'VT'),
  (id: 'QC', label: 'QC'),
  (id: 'VDC', label: 'VDC'),
  (id: 'Installations', label: 'Installations'),
];

Future<bool?> showInterventionCreateSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const InterventionCreateSheet(),
  );
}

class InterventionCreateSheet extends StatefulWidget {
  const InterventionCreateSheet({super.key});

  @override
  State<InterventionCreateSheet> createState() => _InterventionCreateSheetState();
}

class _InterventionCreateSheetState extends State<InterventionCreateSheet> {
  bool _loadingRefs = true;
  String? _refsError;

  List<ClientLite> _clients = [];
  List<Technicien> _techniciens = [];
  List<InterventionProspectCible> _prospectCibles = [];
  List<AgenceClient> _agences = [];

  _TargetType _targetType = _TargetType.client;
  _ProspectMode _prospectMode = _ProspectMode.liste;

  String? _entityCode;
  String? _clientId;
  String? _agenceId;
  String? _prospectCibleKey;
  String? _technicienId;
  String _typeIntervention = 'VT';
  DateTime? _dateIntervention;

  final _prospectNomManuel = TextEditingController();
  final _sujet = TextEditingController();
  final _description = TextEditingController();
  final _ville = TextEditingController();
  final _site = TextEditingController();

  bool _loadingAgences = false;
  bool _submitting = false;

  List<({String id, String label})> get _availableTypes =>
      _targetType == _TargetType.client ? _typesClient : _typesProspect;

  InterventionProspectCible? get _selectedProspectCible {
    if (_prospectCibleKey == null) return null;
    for (final c in _prospectCibles) {
      if (c.key == _prospectCibleKey) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  @override
  void dispose() {
    _prospectNomManuel.dispose();
    _sujet.dispose();
    _description.dispose();
    _ville.dispose();
    _site.dispose();
    super.dispose();
  }

  Future<void> _loadRefs() async {
    setState(() {
      _loadingRefs = true;
      _refsError = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      final results = await Future.wait([
        api.listClientsLite(),
        api.listTechniciens(),
        api.listInterventionProspectCibles(),
      ]);
      if (!mounted) return;
      final codes = auth.entityCodes;
      setState(() {
        _clients = results[0] as List<ClientLite>;
        _techniciens = results[1] as List<Technicien>;
        _prospectCibles = results[2] as List<InterventionProspectCible>;
        if (auth.isEntityScopeAllActive && codes.isNotEmpty) {
          _entityCode = codes.first;
        }
        _loadingRefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refsError = e.toString();
        _loadingRefs = false;
      });
    }
  }

  Future<void> _loadAgences(String clientId) async {
    setState(() {
      _loadingAgences = true;
      _agences = [];
      _agenceId = null;
      _site.clear();
    });
    try {
      final api = context.read<AuthProvider>().api;
      final rows = await api.listAgences(clientId: clientId);
      if (!mounted) return;
      setState(() {
        _agences = rows;
        _loadingAgences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAgences = false);
    }
  }

  void _onTargetTypeChanged(_TargetType v) {
    setState(() {
      _targetType = v;
      _clientId = null;
      _agenceId = null;
      _agences = [];
      _prospectCibleKey = null;
      _prospectNomManuel.clear();
      _site.clear();
      _ville.clear();
      if (v == _TargetType.prospect &&
          (_typeIntervention == 'MT' || _typeIntervention == 'Refill')) {
        _typeIntervention = 'VT';
      }
    });
  }

  void _onAgenceChanged(String? id) {
    AgenceClient? agence;
    if (id != null) {
      for (final a in _agences) {
        if (a.id == id) {
          agence = a;
          break;
        }
      }
    }
    setState(() {
      _agenceId = id;
      _site.text = agence?.nomAgence ?? '';
      if ((agence?.ville ?? '').trim().isNotEmpty) {
        _ville.text = agence!.ville!.trim();
      }
    });
  }

  void _onProspectCibleChanged(String? key) {
    InterventionProspectCible? cible;
    if (key != null) {
      for (final c in _prospectCibles) {
        if (c.key == key) {
          cible = c;
          break;
        }
      }
    }
    setState(() {
      _prospectCibleKey = key;
      if (cible != null) {
        final v = (cible.ville ?? '').trim();
        if (v.isNotEmpty) _ville.text = v;
        if (_sujet.text.trim().isEmpty) {
          _sujet.text = 'Intervention — ${cible.nom}';
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateIntervention ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _dateIntervention = picked);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isEntityScopeAllActive &&
        (_entityCode == null || _entityCode!.trim().isEmpty)) {
      _toast('Veuillez choisir un pays.');
      return;
    }
    if (_targetType == _TargetType.client) {
      if (_clientId == null || _clientId!.isEmpty) {
        _toast('Veuillez sélectionner un client.');
        return;
      }
    } else if (_prospectMode == _ProspectMode.liste) {
      if (_selectedProspectCible == null) {
        _toast('Veuillez sélectionner un prospect.');
        return;
      }
    } else if (_prospectNomManuel.text.trim().isEmpty) {
      _toast('Veuillez saisir le nom du prospect.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = auth.api;
      final body = <String, dynamic>{
        'type_intervention': _typeIntervention,
      };

      if (auth.isEntityScopeAllActive && _entityCode != null) {
        body['entity_code'] = _entityCode!.trim().toUpperCase();
      }

      if (_targetType == _TargetType.client) {
        body['id_clients'] = _clientId;
        if (_agenceId != null && _agenceId!.isNotEmpty) {
          body['id_agence'] = _agenceId;
        }
      } else {
        final cible = _selectedProspectCible;
        if (_prospectMode == _ProspectMode.liste && cible != null) {
          if (cible.idProspect != null && cible.idProspect!.isNotEmpty) {
            body['id_prospect'] = cible.idProspect;
          } else {
            body['prospect_nom_manuel'] = cible.nom;
          }
          body['source_type'] = cible.sourceType;
          body['source_id'] = cible.sourceId;
        } else {
          body['prospect_nom_manuel'] = _prospectNomManuel.text.trim();
        }
      }

      if (_technicienId != null && _technicienId!.isNotEmpty) {
        body['id_technicien'] = _technicienId;
      }
      if (_dateIntervention != null) {
        body['date_intervention'] = _fmtDate(_dateIntervention!);
      }

      final sujet = _sujet.text.trim();
      if (sujet.isNotEmpty) body['sujet'] = sujet;

      final desc = _description.text.trim();
      if (desc.isNotEmpty) body['description'] = desc;

      final ville = _ville.text.trim();
      if (ville.isNotEmpty) body['ville'] = ville;

      final site = _site.text.trim();
      if (site.isNotEmpty) body['site'] = site;

      await api.createIntervention(body);
      if (!mounted) return;
      _toast('Intervention créée');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final auth = context.watch<AuthProvider>();
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return ModernBottomSheetShell(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      margin: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.04),
      child: SizedBox(
        height: sheetHeight,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 1,
          minChildSize: 0.5,
          maxChildSize: 1,
          builder: (context, scrollController) {
          if (_loadingRefs) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_refsError != null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_refsError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadRefs,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
            children: [
              Center(child: modernSheetDragHandle()),
              const SizedBox(height: 20),
              _header(),
              const SizedBox(height: 24),
              if (auth.isEntityScopeAllActive) ...[
                _FormSection(
                  title: 'Pays',
                  icon: Icons.public_rounded,
                  children: [
                    ModernSelectField<String?>(
                      label: 'Entité',
                      hint: 'Choisir un pays',
                      leadingIcon: Icons.flag_outlined,
                      allowClear: false,
                      value: _entityCode,
                      options: auth.entityCodes
                          .map(
                            (c) => ModernSelectOption<String?>(
                              value: c,
                              label: c,
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _entityCode = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _FormSection(
                title: 'Bénéficiaire',
                icon: Icons.person_outline_rounded,
                children: [
                  _SegmentedToggle<_TargetType>(
                    value: _targetType,
                    options: const [
                      (_TargetType.client, 'Client'),
                      (_TargetType.prospect, 'Prospect'),
                    ],
                    onChanged: _onTargetTypeChanged,
                  ),
                  const SizedBox(height: 16),
                  if (_targetType == _TargetType.client) ...[
                    ModernSelectField<String?>(
                      label: 'Client',
                      hint: 'Sélectionner un client',
                      leadingIcon: Icons.business_rounded,
                      value: _clientId,
                      options: _clients
                          .map(
                            (c) => ModernSelectOption<String?>(
                              value: c.id,
                              label: c.nomClient,
                              icon: Icons.storefront_outlined,
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _clientId = v;
                          _agenceId = null;
                          _agences = [];
                          _site.clear();
                          _ville.clear();
                        });
                        if (v != null) _loadAgences(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loadingAgences)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      ModernSelectField<String?>(
                        label: 'Site',
                        hint: _clientId == null
                            ? 'Choisir un client d\'abord'
                            : 'Sélectionner un site',
                        leadingIcon: Icons.location_on_outlined,
                        value: _agenceId,
                        options: _agences
                            .map(
                              (a) => ModernSelectOption<String?>(
                                value: a.id,
                                label: a.label,
                                subtitle: a.ville,
                                icon: Icons.place_outlined,
                              ),
                            )
                            .toList(),
                        onChanged: _clientId == null ? (_) {} : _onAgenceChanged,
                      ),
                  ] else ...[
                    _SegmentedToggle<_ProspectMode>(
                      value: _prospectMode,
                      options: const [
                        (_ProspectMode.liste, 'Liste CRM'),
                        (_ProspectMode.manuel, 'Saisie libre'),
                      ],
                      onChanged: (v) => setState(() {
                        _prospectMode = v;
                        _prospectCibleKey = null;
                        _prospectNomManuel.clear();
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (_prospectMode == _ProspectMode.liste)
                      ModernSelectField<String?>(
                        label: 'Prospect',
                        hint: 'Boutique, offre, prospect commercial…',
                        leadingIcon: Icons.person_search_outlined,
                        value: _prospectCibleKey,
                        options: _prospectCibles
                            .map(
                              (p) => ModernSelectOption<String?>(
                                value: p.key,
                                label: p.label,
                                icon: Icons.person_outline_rounded,
                              ),
                            )
                            .toList(),
                        onChanged: _onProspectCibleChanged,
                      )
                    else
                      _ModernTextField(
                        controller: _prospectNomManuel,
                        label: 'Nom du prospect',
                        required: true,
                        hint: 'Nom ou société',
                      ),
                    const SizedBox(height: 16),
                    _ModernTextField(
                      controller: _site,
                      label: 'Site',
                      hint: 'Libellé du site (texte libre)',
                    ),
                    const SizedBox(height: 14),
                    _ModernTextField(
                      controller: _ville,
                      label: 'Ville',
                      hint: 'Ville',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Intervention',
                icon: Icons.build_outlined,
                children: [
                  if (_targetType == _TargetType.client) ...[
                    _ModernTextField(
                      controller: _ville,
                      label: 'Ville',
                      hint: 'Remplie depuis le site si disponible',
                    ),
                    const SizedBox(height: 14),
                  ],
                  ModernSelectField<String?>(
                    label: 'Type d\'intervention',
                    hint: 'Choisir un type',
                    leadingIcon: Icons.category_outlined,
                    allowClear: false,
                    value: _typeIntervention,
                    options: _availableTypes
                        .map(
                          (t) => ModernSelectOption<String?>(
                            value: t.id,
                            label: t.label,
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _typeIntervention = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  ModernSelectField<String?>(
                    label: 'Technicien',
                    hint: 'Optionnel',
                    leadingIcon: Icons.engineering_outlined,
                    value: _technicienId,
                    options: _techniciens
                        .map(
                          (t) => ModernSelectOption<String?>(
                            value: t.id,
                            label: (t.nom ?? '').trim().isNotEmpty
                                ? t.nom!.trim()
                                : t.id,
                            icon: Icons.person_outline_rounded,
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _technicienId = v),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date intervention',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: AromaColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE4E4E7),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: _dateIntervention != null
                                        ? InterventionsUi.accent
                                        : AromaColors.zinc400,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _dateIntervention != null
                                          ? _fmtDate(_dateIntervention!)
                                          : 'Choisir une date (optionnel)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _dateIntervention != null
                                            ? AromaColors.zinc900
                                            : AromaColors.zinc400,
                                      ),
                                    ),
                                  ),
                                  if (_dateIntervention != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _dateIntervention = null,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: _sujet,
                    label: 'Sujet',
                    hint: 'Sujet de l\'intervention',
                  ),
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'Description de l\'intervention',
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: InterventionsUi.accent,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Créer l\'intervention',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: InterventionsUi.gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle intervention',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Planifier une intervention terrain',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

enum _TargetType { client, prospect }

enum _ProspectMode { liste, manuel }

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AromaColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: InterventionsUi.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AromaColors.zinc900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AromaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: InterventionsUi.accent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentedToggle<T> extends StatelessWidget {
  const _SegmentedToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = value == opt.$1;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(opt.$1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AromaColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    opt.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AromaColors.zinc900
                          : AromaColors.zinc500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
