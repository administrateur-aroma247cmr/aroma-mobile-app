import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rh_dashboard.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/rh/rh_ui.dart';

class RhRecapScreen extends StatefulWidget {
  const RhRecapScreen({
    super.key,
    this.embedded = false,
    this.collaborateurId,
  });

  final bool embedded;
  final String? collaborateurId;

  @override
  State<RhRecapScreen> createState() => _RhRecapScreenState();
}

class _RhRecapScreenState extends State<RhRecapScreen>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  String _mois = currentMonthIso();
  String? _selectedCollabId;
  List<CollaborateurLite> _collaborateurs = [];
  RhDashboardMois? _dash;
  RhHistoriqueArrivee? _historique;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    _selectedCollabId = widget.collaborateurId ?? auth.collaborateurId;
    if (auth.isPrivilegedStaff && widget.collaborateurId == null) {
      try {
        _collaborateurs = await auth.api.listCollaborateursLite();
        if (_selectedCollabId == null && _collaborateurs.isNotEmpty) {
          _selectedCollabId = _collaborateurs.first.id;
        }
      } catch (_) {}
    }
    await _reload();
  }

  Future<void> _reload() async {
    final collabId = _selectedCollabId;
    if (collabId == null || collabId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Aucun collaborateur associé à ce compte.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final results = await Future.wait([
        api.getRhDashboardMois(collabId, mois: _mois),
        api.getRhHistoriqueDepuisArrivee(collabId),
      ]);
      if (!mounted) return;
      setState(() {
        _dash = results[0] as RhDashboardMois;
        _historique = results[1] as RhHistoriqueArrivee;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickMonth() async {
    final parts = _mois.split('-');
    final initial = DateTime(
      int.tryParse(parts.first) ?? DateTime.now().year,
      int.tryParse(parts.length > 1 ? parts[1] : '1') ?? DateTime.now().month,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _mois =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}';
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();
    final canPickCollab =
        auth.isPrivilegedStaff &&
        widget.collaborateurId == null &&
        _collaborateurs.length > 1;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? RhEmptyState(
            title: _error!,
            icon: Icons.error_outline_rounded,
            actionLabel: 'Réessayer',
            onAction: _reload,
          )
        : RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (canPickCollab) ...[
                  _CollabPicker(
                    collaborateurs: _collaborateurs,
                    value: _selectedCollabId,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _selectedCollabId = v);
                      await _reload();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _MonthPicker(
                  label: monthLabelFr(_mois),
                  onTap: _pickMonth,
                ),
                const SizedBox(height: 14),
                RhSectionHeader(
                  title: 'Mon univers',
                  subtitle: _dash?.moisLabelFr ?? monthLabelFr(_mois),
                ),
                const SizedBox(height: 8),
                _MetricGrid(
                  cells: _dash == null
                      ? const []
                      : [
                          _MetricCell(
                            'Retard',
                            '${_dash!.retardOccurrences}',
                            Icons.schedule_rounded,
                            const Color(0xFFB45309),
                          ),
                          _MetricCell(
                            'Absence',
                            '${_dash!.absenceCount}',
                            Icons.event_busy_rounded,
                            const Color(0xFFDC2626),
                          ),
                          _MetricCell(
                            'Absence pointage',
                            '${_dash!.absencePointage}',
                            Icons.fingerprint_outlined,
                            const Color(0xFFEA580C),
                          ),
                          _MetricCell(
                            'Absence samedi',
                            '${_dash!.absenceSamedi}',
                            Icons.weekend_outlined,
                            AromaColors.zinc500,
                          ),
                          _MetricCell(
                            'Vacances (jours)',
                            '${_dash!.vacancesJours}',
                            Icons.beach_access_outlined,
                            const Color(0xFF2563EB),
                          ),
                          _MetricCell(
                            "Demandes d'explication",
                            '${_dash!.demandesExplication}',
                            Icons.help_outline_rounded,
                            const Color(0xFF7C3AED),
                          ),
                          _MetricCell(
                            'Avance salaire',
                            fmtFcfa(_dash!.avanceSalaire),
                            Icons.payments_outlined,
                            RhUi.accent,
                          ),
                          _MetricCell(
                            'Retenu compta',
                            fmtFcfa(_dash!.retenuCompta),
                            Icons.receipt_long_outlined,
                            const Color(0xFFDC2626),
                          ),
                          _MetricCell(
                            'Factures non conformes',
                            '${_dash!.facturesNonConformes}',
                            Icons.warning_amber_rounded,
                            const Color(0xFFEA580C),
                          ),
                          _MetricCell(
                            '5% Rémunération (boutique)',
                            _dash!.boutiqueSeuilAtteint
                                ? fmtFcfa(
                                    _dash!.remuneration5pctBoutiqueIndividuelle,
                                  )
                                : '—',
                            Icons.storefront_outlined,
                            const Color(0xFF059669),
                          ),
                          _MetricCell(
                            "Nombre d'avertissements",
                            '${_dash!.nombreAvertissements}',
                            Icons.gavel_outlined,
                            const Color(0xFFDC2626),
                          ),
                          _MetricCell(
                            '5% Vente directe',
                            fmtFcfa(_dash!.commission5pctVenteDirecte),
                            Icons.trending_up_rounded,
                            const Color(0xFF059669),
                          ),
                          _MetricCell(
                            'Prime rentabilité',
                            fmtFcfa(_dash!.primeRentabilite),
                            Icons.emoji_events_outlined,
                            const Color(0xFFF59E0B),
                          ),
                        ],
                ),
                const SizedBox(height: 16),
                RhSectionHeader(
                  title: _historique?.dateReferenceLabel != null
                      ? 'Historique depuis ${_historique!.dateReferenceLabel}'
                      : 'Historique depuis mon arrivée',
                ),
                const SizedBox(height: 8),
                _MetricGrid(
                  cells: _historique == null
                      ? const []
                      : [
                          _MetricCell(
                            'Absences',
                            '${_historique!.absences}',
                            Icons.event_busy_rounded,
                            const Color(0xFFDC2626),
                          ),
                          _MetricCell(
                            "Demandes d'explication",
                            '${_historique!.demandesExplication}',
                            Icons.help_outline_rounded,
                            const Color(0xFF7C3AED),
                          ),
                          _MetricCell(
                            'Avertissements',
                            '${_historique!.avertissements}',
                            Icons.gavel_outlined,
                            const Color(0xFFEA580C),
                          ),
                          _MetricCell(
                            'Prime totale',
                            fmtFcfa(_historique!.primeTotale),
                            Icons.emoji_events_outlined,
                            const Color(0xFFF59E0B),
                          ),
                          _MetricCell(
                            'Jours congé total',
                            '${_historique!.joursCongeTotal}',
                            Icons.beach_access_outlined,
                            const Color(0xFF2563EB),
                          ),
                        ],
                ),
              ],
            ),
          );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Mon espace RH'),
        actions: const [EntityScopeAppBarAction()],
      ),
      body: body,
    );
  }
}

class _CollabPicker extends StatelessWidget {
  const _CollabPicker({
    required this.collaborateurs,
    required this.value,
    required this.onChanged,
  });

  final List<CollaborateurLite> collaborateurs;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: collaborateurs
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.fullName),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: RhUi.gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Période',
                        style: TextStyle(
                          fontSize: 12,
                          color: AromaColors.zinc500,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AromaColors.zinc500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCell {
  const _MetricCell(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cells});

  final List<_MetricCell> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth > 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: cross == 3 ? 2.6 : 2.35,
          ),
          itemCount: cells.length,
          itemBuilder: (context, i) {
            final cell = cells[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AromaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cell.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(cell.icon, size: 14, color: cell.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cell.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AromaColors.zinc500,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cell.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AromaColors.zinc900,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
