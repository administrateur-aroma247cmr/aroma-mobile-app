import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/intervention.dart';
import '../../providers/auth_provider.dart';
import '../../screens/fiche_adc_screen.dart';
import '../../screens/intervention_create_screen.dart';
import '../../screens/intervention_detail_screen.dart';
import '../../screens/rapport_mensuel_detail_screen.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/intervention_technician_actions.dart';
import '../../utils/technician_view.dart';
import '../../widgets/entity_scope_selector.dart';
import 'interventions_ui.dart';
import '../../screens/reparation_create_screen.dart';
import '../../screens/transport_create_screen.dart';
import 'transport_detail_sheet.dart';

// ─── Mes interventions ─────────────────────────────────────────────────────────

class InterventionsListTab extends StatefulWidget {
  const InterventionsListTab({
    super.key,
    this.fieldActions = false,
    this.filterByAssignment = false,
    this.maskStatuses = false,
  });

  /// Boutons terrain (Démarrer / Créer le rapport) — tous les accès interventions.
  final bool fieldActions;

  /// Technicien : uniquement les interventions assignées.
  final bool filterByAssignment;

  /// Technicien : masque Rapport d'intervention / Rapport envoyé.
  final bool maskStatuses;

  @override
  State<InterventionsListTab> createState() => _InterventionsListTabState();
}

class _InterventionsListTabState extends State<InterventionsListTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<Intervention> _rows = [];
  String _search = '';
  String _monthKey = currentMonthIso();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String get _monthDateMin => '$_monthKey-01';

  String get _monthDateMax {
    final parts = _monthKey.split('-');
    if (parts.length < 2) return _monthDateMin;
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final last = DateTime(y, m + 1, 0);
    return '${last.year.toString().padLeft(4, '0')}-'
        '${last.month.toString().padLeft(2, '0')}-'
        '${last.day.toString().padLeft(2, '0')}';
  }

  void _shiftMonth(int delta) {
    final parts = _monthKey.split('-');
    if (parts.length < 2) return;
    var y = int.tryParse(parts[0]) ?? DateTime.now().year;
    var m = int.tryParse(parts[1]) ?? DateTime.now().month;
    m += delta;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _monthKey = '${y.toString().padLeft(4, '0')}-'
          '${m.toString().padLeft(2, '0')}';
    });
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;

      final result = await api.listInterventions(
        dateFrom: _monthDateMin,
        dateTo: _monthDateMax,
        limit: 500,
      );

      var rows = result.items;
      if (widget.filterByAssignment) {
        final ctx = await buildTechnicianMatchContext(auth);
        rows = rows
            .where((i) => isInterventionAssignedToTechnician(i, ctx))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<Intervention> get _filtered {
    final q = _search.trim().toLowerCase();
    return _rows.where((i) {
      if (q.isEmpty) return true;
      return i.titreAffiche.toLowerCase().contains(q) ||
          (i.clientNom ?? '').toLowerCase().contains(q) ||
          (i.ref ?? '').toLowerCase().contains(q) ||
          (i.typeIntervention ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openIntervention(Intervention i) async {
    final changed = await openInterventionDetail(
      context,
      intervention: i,
      fieldActions: widget.fieldActions,
      maskStatuses: widget.maskStatuses,
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const InterventionCreateScreen(),
      ),
    );
    if (created == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InterventionsSectionHeader(
                  title: 'Mes interventions',
                  subtitle: widget.filterByAssignment
                      ? 'Vos missions du mois'
                      : 'Suivi terrain du mois',
                ),
              ),
              if (!widget.fieldActions)
                FilledButton.icon(
                  onPressed: _openCreate,
                  style: InterventionsUi.compactActionStyle(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Créer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          InterventionsMonthNavigator(
            label: monthLabelFr(_monthKey),
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 14),
          InterventionsSearchField(
            hintText: 'Rechercher client, réf., type…',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            InterventionsEmptyState(
              title: 'Aucune intervention',
              subtitle: widget.filterByAssignment
                  ? 'Aucune intervention ne vous est assignée.'
                  : 'Aucune intervention pour cette période.',
            )
          else
            ...rows.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InterventionsListCard(
                  title: i.titreAffiche,
                  subtitle:
                      '${formatDateFr(i.dateIntervention)} · ${i.typeIntervention ?? '—'} · ${i.clientNom ?? '—'}',
                  trailingWidget: InterventionEtatBadge(
                    etat: widget.maskStatuses
                        ? interventionEtatForTechnicianDisplay(i.etat)
                        : i.etat,
                  ),
                  onTap: () => _openIntervention(i),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Mon calendrier ────────────────────────────────────────────────────────────

class InterventionsCalendarTab extends StatefulWidget {
  const InterventionsCalendarTab({
    super.key,
    this.technicianFieldView = false,
  });

  final bool technicianFieldView;

  @override
  State<InterventionsCalendarTab> createState() =>
      _InterventionsCalendarTabState();
}

class _InterventionsCalendarTabState extends State<InterventionsCalendarTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<Intervention> _rows = [];
  late DateTime _focusedMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _reload();
  }

  String get _monthKey =>
      '${_focusedMonth.year.toString().padLeft(4, '0')}-'
      '${_focusedMonth.month.toString().padLeft(2, '0')}';

  String get _monthDateMin => '$_monthKey-01';

  String get _monthDateMax {
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    return '${last.year.toString().padLeft(4, '0')}-'
        '${last.month.toString().padLeft(2, '0')}-'
        '${last.day.toString().padLeft(2, '0')}';
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      final result = await api.listInterventions(
        dateFrom: _monthDateMin,
        dateTo: _monthDateMax,
        limit: 500,
      );
      var rows = result.items;
      if (widget.technicianFieldView) {
        final ctx = await buildTechnicianMatchContext(auth);
        rows = rows
            .where((i) => isInterventionAssignedToTechnician(i, ctx))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _selectedDay = null;
    });
    _reload();
  }

  Map<int, List<Intervention>> _byDay() {
    final map = <int, List<Intervention>>{};
    for (final i in _rows) {
      final raw = i.dateIntervention;
      if (raw == null || raw.length < 10) continue;
      final d = DateTime.tryParse(raw.substring(0, 10));
      if (d == null) continue;
      if (d.year != _focusedMonth.year || d.month != _focusedMonth.month) {
        continue;
      }
      map.putIfAbsent(d.day, () => []).add(i);
    }
    return map;
  }

  Future<void> _showDetail(Intervention i) async {
    final changed = await openInterventionDetail(
      context,
      intervention: i,
      fieldActions: widget.technicianFieldView,
      maskStatuses: widget.technicianFieldView,
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final byDay = _byDay();
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startPad = first.weekday - 1;
    final selected = _selectedDay;
    final dayItems = selected != null ? (byDay[selected] ?? []) : <Intervention>[];

    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const InterventionsSectionHeader(
            title: 'Mon calendrier',
            subtitle: 'Planning doux du mois',
          ),
          const SizedBox(height: 16),
          InterventionsMonthNavigator(
            label: monthLabelFr(_monthKey),
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final label in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ),
              for (var i = 0; i < startPad; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _CalendarDayCell(
                  day: day,
                  count: byDay[day]?.length ?? 0,
                  selected: selected == day,
                  onTap: () => setState(() => _selectedDay = day),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (selected == null)
            const Text(
              'Sélectionnez un jour pour voir les interventions.',
              style: TextStyle(color: AromaColors.zinc500),
            )
          else if (dayItems.isEmpty)
            Text(
              'Aucune intervention le $selected/${_focusedMonth.month}.',
              style: const TextStyle(color: AromaColors.zinc500),
            )
          else
            ...dayItems.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InterventionsListCard(
                  title: i.titreAffiche,
                  subtitle:
                      '${i.typeIntervention ?? '—'} · ${i.clientNom ?? '—'}',
                  trailingWidget: InterventionEtatBadge(
                    etat: widget.technicianFieldView
                        ? interventionEtatForTechnicianDisplay(i.etat)
                        : i.etat,
                  ),
                  onTap: () => _showDetail(i),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected
                ? InterventionsUi.accent.withValues(alpha: 0.14)
                : (count > 0 ? InterventionsUi.accentMuted : null),
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: InterventionsUi.accent.withValues(alpha: 0.45),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? InterventionsUi.accent
                      : AromaColors.zinc900,
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: InterventionsUi.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

// ─── ADC ───────────────────────────────────────────────────────────────────────

class InterventionsAdcTab extends StatefulWidget {
  const InterventionsAdcTab({super.key});

  @override
  State<InterventionsAdcTab> createState() => _InterventionsAdcTabState();
}

class _InterventionsAdcTabState extends State<InterventionsAdcTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<ExperienceAdc> _rows = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final rows = await api.listExperienceAdc();
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<ExperienceAdc> get _filtered {
    final q = _search.trim().toLowerCase();
    return _rows.where((a) {
      if (q.isEmpty) return true;
      return a.titreAffiche.toLowerCase().contains(q) ||
          (a.siteName ?? '').toLowerCase().contains(q) ||
          (a.statut ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _openFiche(ExperienceAdc adc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FicheAdcScreen(
          adcId: adc.id,
          fallbackSiteName: adc.siteName,
          fallbackDatePlanifiee: adc.datePlanifiee,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const InterventionsSectionHeader(
            title: 'Mes appels de courtoisie (ADC)',
            subtitle: 'Contacts clients après intervention',
          ),
          const SizedBox(height: 14),
          InterventionsSearchField(
            hintText: 'Rechercher client, site, statut…',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const InterventionsEmptyState(
              title: 'Aucun ADC',
              icon: Icons.phone_in_talk_outlined,
            )
          else
            ...rows.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdcListCard(
                  clientName: a.titreAffiche,
                  siteName: a.siteName ?? '—',
                  datePlanifiee: formatDateFr(a.datePlanifiee),
                  statut: a.statut,
                  exchangeCount: a.actionsTrace.isNotEmpty
                      ? a.actionsTrace.length
                      : null,
                  onTap: () => _openFiche(a),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Transport ─────────────────────────────────────────────────────────────────

class InterventionsTransportTab extends StatefulWidget {
  const InterventionsTransportTab({
    super.key,
    this.technicianFieldView = false,
  });

  final bool technicianFieldView;

  @override
  State<InterventionsTransportTab> createState() =>
      _InterventionsTransportTabState();
}

class _InterventionsTransportTabState extends State<InterventionsTransportTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<TransportIntervention> _rows = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      var rows = await api.listTransports();
      if (widget.technicianFieldView) {
        final ctx = await buildTechnicianMatchContext(auth);
        rows = rows
            .where((t) => isTransportAssignedToTechnician(t, ctx))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<TransportIntervention> get _filtered {
    final q = _search.trim().toLowerCase();
    return _rows.where((t) {
      if (q.isEmpty) return true;
      return t.titreAffiche.toLowerCase().contains(q) ||
          (t.ville ?? '').toLowerCase().contains(q) ||
          (t.technicienNom ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _showDetail(TransportIntervention t) {
    showTransportDetailSheet(context, t);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const TransportCreateScreen(),
      ),
    );
    if (created == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: InterventionsSectionHeader(
                  title: 'Mon transport',
                  subtitle: 'Fiches de déplacement terrain',
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreate,
                style: InterventionsUi.compactActionStyle(
                  backgroundColor: const Color(0xFF0891B2),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Nouvelle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InterventionsSearchField(
            hintText: 'Rechercher ville, raison…',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const InterventionsEmptyState(
              title: 'Aucune fiche transport',
              icon: Icons.local_shipping_outlined,
            )
          else
            ...rows.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InterventionsListCard(
                  title: t.titreAffiche,
                  subtitle:
                      '${formatDateFr(t.dateTransport)} · ${t.technicienNom ?? '—'} · ${t.pointsCount} point(s)',
                  trailing:
                      t.montantTotal != null ? fmtFcfa(t.montantTotal) : null,
                  onTap: () => _showDetail(t),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Réparations ─────────────────────────────────────────────────────────────

class InterventionsReparationsTab extends StatefulWidget {
  const InterventionsReparationsTab({
    super.key,
    this.technicianFieldView = false,
  });

  final bool technicianFieldView;

  @override
  State<InterventionsReparationsTab> createState() =>
      _InterventionsReparationsTabState();
}

class _InterventionsReparationsTabState extends State<InterventionsReparationsTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<Reparation> _rows = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      final result = await api.listReparations(limit: 200);
      var rows = result.items;
      if (widget.technicianFieldView) {
        final ctx = await buildTechnicianMatchContext(auth);
        rows = rows
            .where((r) => isReparationAssignedToTechnician(r, ctx))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<Reparation> get _filtered {
    final q = _search.trim().toLowerCase();
    return _rows.where((r) {
      if (q.isEmpty) return true;
      return r.titreAffiche.toLowerCase().contains(q) ||
          r.clientAffiche.toLowerCase().contains(q) ||
          r.statut.toLowerCase().contains(q);
    }).toList();
  }

  void _showDetail(Reparation r) {
    showInterventionsDetailSheet(
      context: context,
      title: 'Réparation',
      children: [
        InterventionsDetailRow('Référence', r.reference ?? '—'),
        InterventionsDetailRow('Client', r.clientAffiche),
        InterventionsDetailRow('Panne', r.panne),
        InterventionsDetailRow('Statut', r.statut),
        InterventionsDetailRow('Technicien', r.technicienNom ?? '—'),
        InterventionsDetailRow('Type diffuseur', r.typeDiffuseur ?? '—'),
        InterventionsDetailRow('Réf. diffuseur', r.referenceDiffuseur ?? '—'),
        if ((r.descriptionProbleme ?? '').trim().isNotEmpty)
          InterventionsDetailRow('Description', r.descriptionProbleme!.trim()),
      ],
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ReparationCreateScreen(),
      ),
    );
    if (created == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: InterventionsSectionHeader(
                  title: 'Mes réparations',
                  subtitle: 'Équipements en dépannage',
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreate,
                style: InterventionsUi.compactActionStyle(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Nouvelle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InterventionsSearchField(
            hintText: 'Rechercher client, réf., statut…',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const InterventionsEmptyState(
              title: 'Aucune réparation',
              icon: Icons.handyman_outlined,
            )
          else
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InterventionsListCard(
                  title: r.titreAffiche,
                  subtitle:
                      '${r.clientAffiche} · ${r.typeDiffuseur ?? '—'} · ${r.statut}',
                  onTap: () => _showDetail(r),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Rapports d'interactions ─────────────────────────────────────────────────

class InterventionsRapportsTab extends StatefulWidget {
  const InterventionsRapportsTab({super.key});

  @override
  State<InterventionsRapportsTab> createState() =>
      _InterventionsRapportsTabState();
}

class _InterventionsRapportsTabState extends State<InterventionsRapportsTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  RapportMensuelSummary? _summary;
  String _monthKey = currentMonthIso();
  String _search = '';
  final _expandedClients = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _shiftMonth(int delta) {
    final parts = _monthKey.split('-');
    if (parts.length < 2) return;
    var y = int.tryParse(parts[0]) ?? DateTime.now().year;
    var m = int.tryParse(parts[1]) ?? DateTime.now().month;
    m += delta;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _monthKey = '${y.toString().padLeft(4, '0')}-'
          '${m.toString().padLeft(2, '0')}';
    });
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final summary = await api.getRapportMensuelSummary(_monthKey);
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  void _openDetail(RapportMensuelClientSummary client) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RapportMensuelDetailScreen(
          clientId: client.clientId,
          clientNom: client.clientNom,
          mois: _monthKey,
        ),
      ),
    );
  }

  List<RapportMensuelClientSummary> get _filteredClients {
    final q = _search.trim().toLowerCase();
    final clients = _summary?.clients ?? [];
    if (q.isEmpty) return clients;
    return clients
        .where((c) => c.clientNom.toLowerCase().contains(q))
        .toList();
  }

  int get _totalInterventions => (_summary?.clients ?? [])
      .fold<int>(0, (sum, c) => sum + c.nbInterventions);

  int get _totalAdc =>
      (_summary?.clients ?? []).fold<int>(0, (sum, c) => sum + c.nbAdc);

  int get _totalVdc =>
      (_summary?.clients ?? []).fold<int>(0, (sum, c) => sum + c.nbVdc);

  void _toggleExpanded(String clientId) {
    setState(() {
      if (_expandedClients.contains(clientId)) {
        _expandedClients.remove(clientId);
      } else {
        _expandedClients.add(clientId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final clients = _filteredClients;
    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const InterventionsSectionHeader(
            title: "Mes rapports d'interactions",
            subtitle: 'Synthèse mensuelle par client',
          ),
          const SizedBox(height: 16),
          InterventionsMonthNavigator(
            label: _summary?.moisLabel.isNotEmpty == true
                ? _summary!.moisLabel
                : monthLabelFr(_monthKey),
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Interventions',
                  value: '$_totalInterventions',
                  color: InterventionsUi.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'ADC',
                  value: '$_totalAdc',
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'VDC',
                  value: '$_totalVdc',
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InterventionsSearchField(
            hintText: 'Rechercher un client…',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          if (clients.isEmpty)
            const InterventionsEmptyState(
              title: 'Aucun rapport pour ce mois',
              icon: Icons.description_outlined,
            )
          else
            ...clients.map((c) {
              final expanded = _expandedClients.contains(c.clientId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    InterventionsListCard(
                      title: c.clientNom,
                      subtitle:
                          '${c.nbInterventions} interv. · ${c.nbAdc} ADC · ${c.nbVdc} VDC · ${c.nbPlanning} plan.',
                      trailing: c.sites.isNotEmpty
                          ? '${c.sites.length} site(s)'
                          : null,
                      icon: expanded
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      onTap: () => _openDetail(c),
                    ),
                    if (c.sites.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _toggleExpanded(c.clientId),
                          icon: Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                          ),
                          label: Text(
                            expanded ? 'Masquer les sites' : 'Voir les sites',
                          ),
                        ),
                      ),
                    if (expanded)
                      ...c.sites.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            bottom: 6,
                          ),
                          child: InterventionsListCard(
                            title: s.site,
                            subtitle:
                                '${s.nbInterventions} interv. · ${s.nbAdc} ADC · ${s.nbVdc} VDC',
                            onTap: () => _openDetail(c),
                            icon: Icons.place_outlined,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InterventionsUi.softCardDecoration(
        borderColor: color.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AromaColors.zinc500,
            ),
          ),
        ],
      ),
    );
  }
}
