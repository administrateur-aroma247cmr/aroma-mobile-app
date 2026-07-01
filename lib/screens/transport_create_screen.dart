import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_lite.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/transport_trajets_data.dart';
import '../widgets/interventions/interventions_ui.dart';
import '../widgets/modern_select_field.dart';

/// Accent transport (aligné transport_detail_sheet / CRM web).
const _transportAccent = Color(0xFF0891B2);
const _transportAccentEnd = Color(0xFF06B6D4);

class TransportCreateScreen extends StatefulWidget {
  const TransportCreateScreen({super.key});

  @override
  State<TransportCreateScreen> createState() => _TransportCreateScreenState();
}

class _TransportCreateScreenState extends State<TransportCreateScreen> {
  bool _loadingRefs = true;
  String? _refsError;

  List<CollaborateurLite> _collaborateurs = [];
  List<ClientLite> _clients = [];

  String? _collaborateurId;
  String? _ville;
  DateTime _dateTransport = DateTime.now();
  final _raison = TextEditingController();
  final _montantTotalOverride = TextEditingController();
  final List<_TransportPointForm> _points = [_TransportPointForm()];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  @override
  void dispose() {
    _raison.dispose();
    _montantTotalOverride.dispose();
    for (final p in _points) {
      p.montant.dispose();
    }
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
        api.listCollaborateurs(),
        api.listClientsLite(),
      ]);
      if (!mounted) return;
      final rawCollabs = results[0] as List<Map<String, dynamic>>;
      final collabs = rawCollabs
          .where(_collaborateurActif)
          .map(CollaborateurLite.fromJson)
          .toList()
        ..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      setState(() {
        _collaborateurs = collabs;
        _clients = results[1] as List<ClientLite>;
        _collaborateurId = auth.collaborateurId ??
            (collabs.length == 1 ? collabs.first.id : null);
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

  bool _collaborateurActif(Map<String, dynamic> m) {
    final v = m['est_actif'] ?? m['actif'];
    return v != false;
  }

  double get _computedTotal {
    var sum = 0.0;
    for (final p in _points) {
      final v = double.tryParse(p.montant.text.replaceAll(',', '.'));
      if (v != null) sum += v;
    }
    return sum;
  }

  double get _totalAffiche {
    final override = _montantTotalOverride.text.trim();
    if (override.isNotEmpty) {
      return double.tryParse(override.replaceAll(',', '.')) ?? _computedTotal;
    }
    return _computedTotal;
  }

  void _setVille(String? v) {
    setState(() {
      _ville = v;
      for (final p in _points) {
        p.quartierDepart = null;
        p.quartierArrivee = null;
        p.idClientDepart = null;
        p.clientNomDepart = null;
        p.idClient = null;
        p.clientNom = null;
        p.montant.clear();
      }
    });
  }

  void _addPoint() {
    setState(() {
      final last = _points.isNotEmpty ? _points.last : null;
      final next = _TransportPointForm();
      final qDep = last?.quartierArrivee;
      if (qDep != null && qDep.isNotEmpty) {
        next.quartierDepart = qDep;
        next._syncMontant(_ville);
      }
      _points.add(next);
    });
  }

  void _removePoint(int index) {
    if (_points.length <= 1) return;
    setState(() {
      _points[index].montant.dispose();
      _points.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTransport,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _dateTransport = picked);
  }

  String _dateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_collaborateurId == null || _collaborateurId!.isEmpty) {
      _toast('Sélectionnez un collaborateur.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = context.read<AuthProvider>().api;
      final pts = <Map<String, dynamic>>[];
      for (final p in _points) {
        final qDep = p.quartierDepart ?? '';
        final qArr = p.quartierArrivee ?? '';
        final montant = double.tryParse(p.montant.text.replaceAll(',', '.'));
        pts.add({
          if (qDep.isNotEmpty) 'lieu_depart': qDep,
          if (qDep.isNotEmpty) 'quartier_depart': qDep,
          if ((p.clientNomDepart ?? '').isNotEmpty)
            'client_nom_depart': p.clientNomDepart,
          if ((p.idClientDepart ?? '').isNotEmpty)
            'id_client_depart': p.idClientDepart,
          if ((p.clientNom ?? '').isNotEmpty) 'client_nom': p.clientNom,
          if ((p.idClient ?? '').isNotEmpty) 'id_client': p.idClient,
          if (qArr.isNotEmpty) 'lieu_arrivee': qArr,
          if (qArr.isNotEmpty) 'quartier_arrivee': qArr,
          if (montant != null) 'montant': montant,
        });
      }

      final body = <String, dynamic>{
        'date_transport': _dateIso(_dateTransport),
        'id_technicien': _collaborateurId,
        if (_raison.text.trim().isNotEmpty)
          'raison_deplacement': _raison.text.trim(),
        if ((_ville ?? '').isNotEmpty) 'ville': _ville,
        'montant_total': _totalAffiche,
        'points': pts,
      };

      await api.createTransport(body);
      if (!mounted) return;
      _toast('Fiche transport créée');
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
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Nouvelle fiche transport'),
        backgroundColor: AromaColors.canvas,
        foregroundColor: AromaColors.zinc900,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: _buildBody(),
      bottomNavigationBar: _loadingRefs || _refsError != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
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
            FilledButton(onPressed: _loadRefs, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _header(),
        const SizedBox(height: 20),
        _FormSection(
          title: 'Informations générales',
          icon: Icons.info_outline_rounded,
          accent: _transportAccent,
          children: [
            ModernSelectField<String?>(
              label: 'Collaborateur',
              hint: 'Choisir un collaborateur',
              leadingIcon: Icons.person_outline_rounded,
              allowClear: false,
              value: _collaborateurId,
              options: _collaborateurs
                  .map(
                    (c) => ModernSelectOption<String?>(
                      value: c.id,
                      label: c.fullName.isNotEmpty ? c.fullName : c.id,
                      icon: Icons.badge_outlined,
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _collaborateurId = v),
            ),
            const SizedBox(height: 16),
            ModernSelectField<String?>(
              label: 'Ville',
              hint: 'Choisir une ville',
              leadingIcon: Icons.location_city_outlined,
              value: _ville,
              options: getVillesTransport()
                  .map(
                    (v) => ModernSelectOption<String?>(
                      value: v,
                      label: v,
                      icon: Icons.map_outlined,
                    ),
                  )
                  .toList(),
              onChanged: _setVille,
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Date',
              value: formatDateFr(_dateIso(_dateTransport)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            _ModernTextField(
              controller: _raison,
              label: 'Raison du déplacement',
              hint: 'Ex: Intervention client, transfert matériel…',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _FormSection(
          title: 'Trajets',
          icon: Icons.route_rounded,
          accent: _transportAccent,
          trailing: TextButton.icon(
            onPressed: _addPoint,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter'),
            style: TextButton.styleFrom(
              foregroundColor: _transportAccent,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          children: [
            for (var i = 0; i < _points.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _TrajetCard(
                index: i + 1,
                point: _points[i],
                ville: _ville,
                clients: _clients,
                canRemove: _points.length > 1,
                onRemove: () => _removePoint(i),
                onChanged: () => setState(() {}),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _TotalCard(
          total: _totalAffiche,
          computed: _computedTotal,
          overrideController: _montantTotalOverride,
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_transportAccent, _transportAccentEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _transportAccent.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
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
                  'Fiche de déplacement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Collaborateur, ville et trajets — total calculé automatiquement',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        border: Border(top: BorderSide(color: AromaColors.zinc200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  fmtFcfa(_totalAffiche),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AromaColors.zinc900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Créer la fiche',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransportPointForm {
  String? quartierDepart;
  String? quartierArrivee;
  String? idClientDepart;
  String? clientNomDepart;
  String? idClient;
  String? clientNom;
  final montant = TextEditingController();

  void _syncMontant(String? ville) {
    final qDep = quartierDepart ?? '';
    final qArr = quartierArrivee ?? '';
    final auto = montantPourQuartiers(ville, qDep, qArr);
    if (auto != null) montant.text = auto;
  }

  void updateQuartierDepart(String? ville, String? value) {
    quartierDepart = value;
    final arrivals = ville != null && value != null
        ? getQuartiersArrivee(ville, value)
        : <String>[];
    if (quartierArrivee != null && !arrivals.contains(quartierArrivee)) {
      quartierArrivee = null;
    }
    _syncMontant(ville);
  }

  void updateQuartierArrivee(String? ville, String? value) {
    quartierArrivee = value;
    _syncMontant(ville);
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accent,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? InterventionsUi.accent;
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
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AromaColors.zinc900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
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
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
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
              borderSide: const BorderSide(color: _transportAccent, width: 1.5),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AromaColors.zinc500.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AromaColors.zinc900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AromaColors.zinc400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrajetCard extends StatelessWidget {
  const _TrajetCard({
    required this.index,
    required this.point,
    required this.ville,
    required this.clients,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _TransportPointForm point;
  final String? ville;
  final List<ClientLite> clients;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final depOptions = ville != null ? getQuartiersDepart(ville) : <String>[];
    final arrOptions = ville != null && (point.quartierDepart ?? '').isNotEmpty
        ? getQuartiersArrivee(ville!, point.quartierDepart!)
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AromaColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_transportAccent, _transportAccentEnd],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _trajetLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AromaColors.zinc900,
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AromaColors.zinc500,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Supprimer le trajet',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ModernSelectField<String?>(
              label: 'Quartier départ',
              hint: ville != null ? 'Choisir le quartier' : 'Choisir la ville d\'abord',
              leadingIcon: Icons.trip_origin_rounded,
              allowClear: false,
              value: point.quartierDepart,
              options: depOptions
                  .map(
                    (q) => ModernSelectOption<String?>(
                      value: q,
                      label: q,
                    ),
                  )
                  .toList(),
              onChanged: ville == null
                  ? (_) {}
                  : (v) {
                      point.updateQuartierDepart(ville, v);
                      onChanged();
                    },
            ),
            const SizedBox(height: 12),
            ModernSelectField<String?>(
              label: 'Client départ (optionnel)',
              hint: 'Associer un client',
              leadingIcon: Icons.storefront_outlined,
              value: point.idClientDepart,
              options: clients
                  .map(
                    (c) => ModernSelectOption<String?>(
                      value: c.id,
                      label: c.nomClient,
                      icon: Icons.business_outlined,
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                ClientLite? client;
                if (v != null) {
                  for (final c in clients) {
                    if (c.id == v) {
                      client = c;
                      break;
                    }
                  }
                }
                point.idClientDepart = v;
                point.clientNomDepart = client?.nomClient;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            ModernSelectField<String?>(
              label: 'Quartier arrivée',
              hint: (point.quartierDepart ?? '').isEmpty
                  ? 'Choisir le départ d\'abord'
                  : 'Choisir le quartier',
              leadingIcon: Icons.place_outlined,
              allowClear: false,
              value: point.quartierArrivee,
              options: arrOptions
                  .map(
                    (q) => ModernSelectOption<String?>(
                      value: q,
                      label: q,
                    ),
                  )
                  .toList(),
              onChanged: (point.quartierDepart ?? '').isEmpty || ville == null
                  ? (_) {}
                  : (v) {
                      point.updateQuartierArrivee(ville, v);
                      onChanged();
                    },
            ),
            const SizedBox(height: 12),
            ModernSelectField<String?>(
              label: 'Client arrivée (optionnel)',
              hint: 'Associer un client',
              leadingIcon: Icons.storefront_outlined,
              value: point.idClient,
              options: clients
                  .map(
                    (c) => ModernSelectOption<String?>(
                      value: c.id,
                      label: c.nomClient,
                      icon: Icons.business_outlined,
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                ClientLite? client;
                if (v != null) {
                  for (final c in clients) {
                    if (c.id == v) {
                      client = c;
                      break;
                    }
                  }
                }
                point.idClient = v;
                point.clientNom = client?.nomClient;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            _ModernTextField(
              controller: point.montant,
              label: 'Montant (FCFA)',
              hint: 'Calculé automatiquement',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }

  String get _trajetLabel {
    final dep = point.quartierDepart ?? '';
    final arr = point.quartierArrivee ?? '';
    if (dep.isEmpty && arr.isEmpty) return 'Trajet $index';
    return '${dep.isEmpty ? '?' : dep} → ${arr.isEmpty ? '?' : arr}';
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.computed,
    required this.overrideController,
    required this.onChanged,
  });

  final double total;
  final double computed;
  final TextEditingController overrideController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTANT TOTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fmtFcfa(total),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (computed > 0 && overrideController.text.trim().isEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Calculé automatiquement à partir des trajets',
              style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Remplacer le total (optionnel)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: overrideController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: computed > 0
                  ? '${computed.toStringAsFixed(0)} (auto)'
                  : 'Auto',
              hintStyle: const TextStyle(color: Color(0xFF52525B)),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
