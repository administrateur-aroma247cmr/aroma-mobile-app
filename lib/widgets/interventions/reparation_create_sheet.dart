import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/client_lite.dart';
import '../../models/equipement_client.dart';
import '../../models/prospect_lite.dart';
import '../../models/stock_lite.dart';
import '../../models/technicien.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../modern_bottom_sheet.dart';
import '../modern_select_field.dart';
import 'interventions_ui.dart';

const _panneOptions = <({String value, String label, IconData icon})>[
  (value: 'bruit', label: 'Ça fait du bruit', icon: Icons.volume_up_outlined),
  (
    value: 'diffuseur_bouche',
    label: 'Diffuseur bouché',
    icon: Icons.block_outlined,
  ),
  (value: 'bip', label: 'Bip', icon: Icons.notifications_active_outlined),
  (
    value: 'bruit_anormal',
    label: 'Bruit anormal',
    icon: Icons.hearing_disabled_outlined,
  ),
  (
    value: 'senteur_faible',
    label: 'Senteur faible',
    icon: Icons.air_outlined,
  ),
  (
    value: 'ne_sallume_plus',
    label: "Ne s'allume plus",
    icon: Icons.power_off_outlined,
  ),
  (
    value: 'ne_diffuse_plus',
    label: 'Ne diffuse plus',
    icon: Icons.water_drop_outlined,
  ),
  (value: 'autre', label: 'Autre', icon: Icons.more_horiz_rounded),
];

Future<bool?> showReparationCreateSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ReparationCreateSheet(),
  );
}

class ReparationCreateSheet extends StatefulWidget {
  const ReparationCreateSheet({super.key});

  @override
  State<ReparationCreateSheet> createState() => _ReparationCreateSheetState();
}

class _ReparationCreateSheetState extends State<ReparationCreateSheet> {
  bool _loadingRefs = true;
  String? _refsError;

  List<ClientLite> _clients = [];
  List<Technicien> _techniciens = [];
  List<StockLite> _stocks = [];
  List<ProspectLite> _prospects = [];

  _TargetType _targetType = _TargetType.client;
  _ProspectMode _prospectMode = _ProspectMode.liste;
  _DiffuseurSource _diffuseurSource = _DiffuseurSource.kyc;

  String? _clientId;
  String? _prospectId;
  String? _technicienId;
  String? _equipementId;
  String? _stockDiffuseurId;
  String _panne = 'bruit';
  String _ticketDestinataire = 'proprietaire';

  final _prospectNomManuel = TextEditingController();
  final _panneAutre = TextEditingController();
  final _description = TextEditingController();
  final _referenceDiffuseur = TextEditingController();
  final _proprietaireNom = TextEditingController();
  final _proprietairePrenom = TextEditingController();
  final _proprietaireWhatsapp = TextEditingController();
  final _deposantNom = TextEditingController();
  final _deposantPrenom = TextEditingController();
  final _deposantWhatsapp = TextEditingController();

  List<EquipementClient> _equipements = [];
  bool _loadingEquipements = false;
  bool _referenceTouched = false;
  bool _submitting = false;
  final List<String> _photoPaths = [];

  List<StockLite> get _stockDiffuseurs =>
      _stocks.where((s) => s.isDiffuseur).toList();

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  @override
  void dispose() {
    _prospectNomManuel.dispose();
    _panneAutre.dispose();
    _description.dispose();
    _referenceDiffuseur.dispose();
    _proprietaireNom.dispose();
    _proprietairePrenom.dispose();
    _proprietaireWhatsapp.dispose();
    _deposantNom.dispose();
    _deposantPrenom.dispose();
    _deposantWhatsapp.dispose();
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
        api.listStocks(),
        api.listProspectsCommerciaux(),
      ]);
      if (!mounted) return;
      final techId = auth.technicienId;
      setState(() {
        _clients = results[0] as List<ClientLite>;
        _techniciens = results[1] as List<Technicien>;
        _stocks = results[2] as List<StockLite>;
        _prospects = results[3] as List<ProspectLite>;
        _technicienId = techId;
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

  Future<void> _loadEquipements(String clientId) async {
    setState(() {
      _loadingEquipements = true;
      _equipements = [];
      _equipementId = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final rows = await api.listEquipements(clientId: clientId);
      if (!mounted) return;
      setState(() {
        _equipements = rows;
        _loadingEquipements = false;
        if (rows.isEmpty) _diffuseurSource = _DiffuseurSource.stock;
      });
      _maybeSuggestReference();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEquipements = false;
        _diffuseurSource = _DiffuseurSource.stock;
      });
    }
  }

  void _maybeSuggestReference() {
    if (_referenceTouched) return;
    String? suggested;
    if (_equipementId != null) {
      for (final e in _equipements) {
        if (e.id == _equipementId) {
          final ref = (e.reference ?? '').trim();
          if (ref.isNotEmpty) suggested = ref;
          break;
        }
      }
    }
    if (suggested == null && _stockDiffuseurId != null) {
      for (final s in _stockDiffuseurs) {
        if (s.id == _stockDiffuseurId) {
          final ref = (s.refJpc ?? '').trim();
          if (ref.isNotEmpty) suggested = ref;
          break;
        }
      }
    }
    if (suggested != null) {
      _referenceDiffuseur.text = suggested;
    }
  }

  String _equipementLabel(EquipementClient e) {
    final parts = [
      e.typeDiffuseur,
      e.reference,
      e.emplacement,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' — ') : 'Appareil';
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty || !mounted) return;
    setState(() {
      for (final img in images) {
        if (img.path.isNotEmpty) _photoPaths.add(img.path);
      }
    });
  }

  Future<void> _pickDocuments() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null || !mounted) return;
    setState(() {
      for (final f in res.files) {
        final path = f.path;
        if (path != null && path.isNotEmpty) _photoPaths.add(path);
      }
    });
  }

  bool get _hasWhatsapp =>
      _proprietaireWhatsapp.text.trim().isNotEmpty ||
      _deposantWhatsapp.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (_targetType == _TargetType.client) {
      if (_clientId == null || _clientId!.isEmpty) {
        _toast('Sélectionnez un client.');
        return;
      }
      if (_loadingEquipements) {
        _toast('Chargement des équipements…');
        return;
      }
      final useKyc =
          _equipements.isNotEmpty && _diffuseurSource == _DiffuseurSource.kyc;
      if (useKyc) {
        if (_equipementId == null || _equipementId!.isEmpty) {
          _toast('Sélectionnez un diffuseur (KYC).');
          return;
        }
      } else {
        if (_stockDiffuseurs.isEmpty) {
          _toast('Aucun diffuseur disponible dans le stock.');
          return;
        }
        if (_stockDiffuseurId == null || _stockDiffuseurId!.isEmpty) {
          _toast('Sélectionnez un diffuseur du stock.');
          return;
        }
      }
    } else {
      if (_prospectMode == _ProspectMode.liste) {
        if (_prospectId == null || _prospectId!.isEmpty) {
          _toast('Sélectionnez un prospect.');
          return;
        }
      } else if (_prospectNomManuel.text.trim().isEmpty) {
        _toast('Saisissez le nom du prospect.');
        return;
      }
      if (_stockDiffuseurs.isEmpty) {
        _toast('Aucun diffuseur disponible dans le stock.');
        return;
      }
      if (_stockDiffuseurId == null || _stockDiffuseurId!.isEmpty) {
        _toast('Sélectionnez un diffuseur du stock.');
        return;
      }
    }

    if (_panne == 'autre' && _panneAutre.text.trim().isEmpty) {
      _toast('Précisez la panne pour « Autre ».');
      return;
    }
    if (_proprietaireNom.text.trim().isEmpty ||
        _proprietairePrenom.text.trim().isEmpty) {
      _toast('Nom et prénom du propriétaire obligatoires.');
      return;
    }
    if (!_hasWhatsapp) {
      _toast('Indiquez au moins un numéro WhatsApp (propriétaire ou déposant).');
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;

      List<Map<String, dynamic>>? photosCreation;
      if (_photoPaths.isNotEmpty) {
        final docs = await api.uploadReparationDocuments(_photoPaths);
        photosCreation = docs
            .map(
              (d) => {
                'path': d['path'] ?? d['url'] ?? '',
                'name': d['name'] ?? 'Fichier',
              },
            )
            .where((d) => '${d['path']}'.trim().isNotEmpty)
            .toList();
        if (photosCreation.isEmpty) photosCreation = null;
      }

      final body = <String, dynamic>{
        'panne': _panne,
        'proprietaire_nom': _proprietaireNom.text.trim(),
        'proprietaire_prenom': _proprietairePrenom.text.trim(),
        'ticket_depot_destinataire': _ticketDestinataire,
      };

      final panneAutre = _panneAutre.text.trim();
      if (panneAutre.isNotEmpty) body['panne_autre_detail'] = panneAutre;

      final desc = _description.text.trim();
      if (desc.isNotEmpty) body['description_probleme'] = desc;

      final refDiff = _referenceDiffuseur.text.trim();
      if (refDiff.isNotEmpty) body['reference_diffuseur'] = refDiff;

      if (_technicienId != null && _technicienId!.isNotEmpty) {
        body['id_technicien'] = _technicienId;
      }

      if (photosCreation != null) body['photos_creation'] = photosCreation;

      final propWa = _proprietaireWhatsapp.text.trim();
      if (propWa.isNotEmpty) body['proprietaire_whatsapp'] = propWa;

      final depNom = _deposantNom.text.trim();
      if (depNom.isNotEmpty) body['deposant_nom'] = depNom;
      final depPrenom = _deposantPrenom.text.trim();
      if (depPrenom.isNotEmpty) body['deposant_prenom'] = depPrenom;
      final depWa = _deposantWhatsapp.text.trim();
      if (depWa.isNotEmpty) body['deposant_whatsapp'] = depWa;

      if (_targetType == _TargetType.client) {
        body['id_clients'] = _clientId;
        final useKyc =
            _equipements.isNotEmpty && _diffuseurSource == _DiffuseurSource.kyc;
        if (useKyc) {
          body['id_equipement'] = _equipementId;
        } else {
          body['stock_diffuseur_id'] = _stockDiffuseurId;
        }
      } else {
        if (_prospectMode == _ProspectMode.liste) {
          body['id_prospect'] = _prospectId;
        } else {
          body['prospect_nom_manuel'] = _prospectNomManuel.text.trim();
        }
        body['stock_diffuseur_id'] = _stockDiffuseurId;
      }

      final created = await api.createReparation(body);

      final imagePaths = _photoPaths.where((p) {
        final lower = p.toLowerCase();
        return lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.heic');
      }).toList();

      try {
        await api.sendReparationTicketDepot(
          created.id,
          filePaths: imagePaths,
        );
        if (!mounted) return;
        _toast('Réparation créée — ticket de dépôt envoyé par WhatsApp');
      } catch (_) {
        if (!mounted) return;
        _toast('Réparation créée (ticket WhatsApp non envoyé)');
      }

      if (!mounted) return;
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
                    onChanged: (v) => setState(() {
                      _targetType = v;
                      _clientId = null;
                      _prospectId = null;
                      _equipements = [];
                      _equipementId = null;
                      _stockDiffuseurId = null;
                    }),
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
                          _equipementId = null;
                          _stockDiffuseurId = null;
                          _referenceTouched = false;
                        });
                        if (v != null) _loadEquipements(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _clientDiffuseurBlock(),
                  ] else ...[
                    _SegmentedToggle<_ProspectMode>(
                      value: _prospectMode,
                      options: const [
                        (_ProspectMode.liste, 'Liste CRM'),
                        (_ProspectMode.manuel, 'Saisie libre'),
                      ],
                      onChanged: (v) => setState(() {
                        _prospectMode = v;
                        _prospectId = null;
                        _prospectNomManuel.clear();
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (_prospectMode == _ProspectMode.liste)
                      ModernSelectField<String?>(
                        label: 'Prospect',
                        hint: 'Sélectionner un prospect',
                        leadingIcon: Icons.person_search_outlined,
                        value: _prospectId,
                        options: _prospects
                            .map(
                              (p) => ModernSelectOption<String?>(
                                value: p.id,
                                label: p.label,
                                icon: Icons.person_outline_rounded,
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _prospectId = v),
                      )
                    else
                      _ModernTextField(
                        controller: _prospectNomManuel,
                        label: 'Nom du prospect',
                        required: true,
                        hint: 'Nom ou société',
                      ),
                    const SizedBox(height: 16),
                    _stockDiffuseurSelect(),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Panne signalée',
                icon: Icons.warning_amber_outlined,
                children: [
                  _PanneGrid(
                    value: _panne,
                    onChanged: (v) => setState(() => _panne = v),
                  ),
                  if (_panne == 'autre') ...[
                    const SizedBox(height: 14),
                    _ModernTextField(
                      controller: _panneAutre,
                      label: 'Précision panne',
                      required: true,
                      hint: 'Décrivez la panne…',
                    ),
                  ],
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: _description,
                    label: 'Description du problème',
                    hint: 'Contexte, symptômes…',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Appareil',
                icon: Icons.devices_other_outlined,
                children: [
                  _ModernTextField(
                    controller: _referenceDiffuseur,
                    label: 'Référence diffuseur',
                    hint: 'N° de série / référence unique',
                    onChanged: (_) => _referenceTouched = true,
                  ),
                  if (_techniciens.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ModernSelectField<String?>(
                      label: 'Technicien assigné',
                      hint: 'Optionnel',
                      leadingIcon: Icons.engineering_outlined,
                      value: _technicienId,
                      options: _techniciens
                          .map(
                            (t) => ModernSelectOption<String?>(
                              value: t.id,
                              label: t.nom ?? 'Technicien',
                              icon: Icons.badge_outlined,
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _technicienId = v),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Contacts & ticket de dépôt',
                icon: Icons.contact_phone_outlined,
                children: [
                  _ModernTextField(
                    controller: _proprietaireNom,
                    label: 'Nom propriétaire',
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _ModernTextField(
                    controller: _proprietairePrenom,
                    label: 'Prénom propriétaire',
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _ModernTextField(
                    controller: _proprietaireWhatsapp,
                    label: 'WhatsApp propriétaire',
                    hint: '+237…',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Déposant (optionnel)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ModernTextField(
                    controller: _deposantNom,
                    label: 'Nom déposant',
                  ),
                  const SizedBox(height: 12),
                  _ModernTextField(
                    controller: _deposantPrenom,
                    label: 'Prénom déposant',
                  ),
                  const SizedBox(height: 12),
                  _ModernTextField(
                    controller: _deposantWhatsapp,
                    label: 'WhatsApp déposant',
                    hint: '+237…',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _SegmentedToggle<String>(
                    value: _ticketDestinataire,
                    options: const [
                      ('proprietaire', 'Ticket → propriétaire'),
                      ('deposant', 'Ticket → déposant'),
                    ],
                    onChanged: (v) => setState(() => _ticketDestinataire = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Photos & justificatifs',
                icon: Icons.photo_camera_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickPhotos,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Photos'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickDocuments,
                          icon: const Icon(Icons.attach_file_outlined),
                          label: const Text('Fichiers'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_photoPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _photoPaths.asMap().entries.map((e) {
                        return InputChip(
                          label: Text(
                            'Fichier ${e.key + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: _submitting
                              ? null
                              : () => setState(() => _photoPaths.removeAt(e.key)),
                        );
                      }).toList(),
                    ),
                  ],
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
                        'Créer la réparation',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
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
              Icons.handyman_outlined,
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
                  'Nouvelle réparation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Enregistrement d\'un équipement en dépannage',
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

  Widget _clientDiffuseurBlock() {
    if (_clientId == null) {
      return const Text(
        'Choisissez d\'abord un client pour charger ses appareils.',
        style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
      );
    }
    if (_loadingEquipements) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement des équipements…'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_equipements.isNotEmpty) ...[
          _SegmentedToggle<_DiffuseurSource>(
            value: _diffuseurSource,
            options: const [
              (_DiffuseurSource.kyc, 'Équipement KYC'),
              (_DiffuseurSource.stock, 'Stock'),
            ],
            onChanged: (v) => setState(() {
              _diffuseurSource = v;
              if (v == _DiffuseurSource.kyc) {
                _stockDiffuseurId = null;
              } else {
                _equipementId = null;
              }
              _referenceTouched = false;
              _maybeSuggestReference();
            }),
          ),
          const SizedBox(height: 16),
        ] else
          const Text(
            'Aucun équipement KYC — choisissez un diffuseur du stock.',
            style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
          ),
        if (_equipements.isNotEmpty &&
            _diffuseurSource == _DiffuseurSource.kyc)
          ModernSelectField<String?>(
            label: 'Diffuseur KYC',
            hint: 'Sélectionner un appareil',
            leadingIcon: Icons.air_outlined,
            value: _equipementId,
            options: _equipements
                .map(
                  (e) => ModernSelectOption<String?>(
                    value: e.id,
                    label: _equipementLabel(e),
                    icon: Icons.devices_other_outlined,
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                _equipementId = v;
                _referenceTouched = false;
              });
              _maybeSuggestReference();
            },
          )
        else
          _stockDiffuseurSelect(),
      ],
    );
  }

  Widget _stockDiffuseurSelect() {
    if (_stockDiffuseurs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'Aucun article « diffuseur » dans le stock.',
          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
        ),
      );
    }
    return ModernSelectField<String?>(
      label: 'Diffuseur (stock)',
      hint: 'Sélectionner un article',
      leadingIcon: Icons.inventory_2_outlined,
      value: _stockDiffuseurId,
      options: _stockDiffuseurs
          .map(
            (s) => ModernSelectOption<String?>(
              value: s.id,
              label: s.label,
              icon: Icons.inventory_2_outlined,
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          _stockDiffuseurId = v;
          _referenceTouched = false;
        });
        _maybeSuggestReference();
      },
    );
  }
}

enum _TargetType { client, prospect }

enum _ProspectMode { liste, manuel }

enum _DiffuseurSource { kyc, stock }

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
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

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
          keyboardType: keyboardType,
          onChanged: onChanged,
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
                      fontSize: 12,
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

class _PanneGrid extends StatelessWidget {
  const _PanneGrid({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _panneOptions.map((opt) {
        final selected = value == opt.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(opt.value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: (MediaQuery.sizeOf(context).width - 96) / 2,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? InterventionsUi.accent.withValues(alpha: 0.12)
                    : AromaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? InterventionsUi.accent
                      : const Color(0xFFE4E4E7),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    opt.icon,
                    size: 18,
                    color: selected
                        ? InterventionsUi.accent
                        : AromaColors.zinc500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? InterventionsUi.gradientStart
                            : AromaColors.zinc500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
