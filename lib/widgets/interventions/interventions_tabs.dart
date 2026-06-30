import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/intervention.dart';
import '../../providers/auth_provider.dart';
import '../../screens/fiche_adc_screen.dart';
import '../../screens/intervention_rapport_screen.dart';
import '../../screens/rapport_mensuel_detail_screen.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/technician_view.dart';
import '../../widgets/entity_scope_selector.dart';
import 'interventions_ui.dart';
import 'transport_detail_sheet.dart';

// ─── Mes interventions ─────────────────────────────────────────────────────────

class InterventionsListTab extends StatefulWidget {
  const InterventionsListTab({
    super.key,
    this.technicianFieldView = false,
  });

  /// Vue terrain : uniquement les interventions assignées au technicien connecté.
  final bool technicianFieldView;

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

      final InterventionsListResult result;
      if (widget.technicianFieldView) {
        final range = technicianInterventionDateRange();
        result = await api.listInterventions(
          dateFrom: range.from,
          dateTo: range.to,
          limit: 500,
        );
      } else {
        result = await api.listInterventions(
          dateFrom: _monthDateMin,
          dateTo: _monthDateMax,
          limit: 500,
        );
      }

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

  void _openIntervention(Intervention i) {
    if (widget.technicianFieldView) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InterventionRapportScreen(
            interventionId: i.id,
            interventionSummary: i,
          ),
        ),
      );
      return;
    }
    showInterventionsDetailSheet(
      context: context,
      title: 'Intervention',
      children: interventionDetailRows(i),
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
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InterventionsSectionHeader(
            title: 'Mes interventions',
            subtitle: widget.technicianFieldView
                ? 'Touchez une intervention pour créer le rapport photos'
                : 'Interventions terrain — aligné CRM web',
          ),
          if (!widget.technicianFieldView) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    monthLabelFr(_monthKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher client, réf., type…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            InterventionsEmptyState(
              title: 'Aucune intervention',
              subtitle: widget.technicianFieldView
                  ? 'Aucune intervention ne vous est assignée.'
                  : 'Aucune intervention pour cette période.',
            )
          else
            ...rows.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InterventionsListCard(
                  title: i.titreAffiche,
                  subtitle:
                      '${formatDateFr(i.dateIntervention)} · ${i.typeIntervention ?? '—'} · ${i.clientNom ?? '—'}',
                  trailingWidget: InterventionEtatBadge(etat: i.etat),
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
  const InterventionsCalendarTab({super.key});

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
      final api = context.read<AuthProvider>().api;
      final result = await api.listInterventions(
        dateFrom: _monthDateMin,
        dateTo: _monthDateMax,
        limit: 500,
      );
      if (!mounted) return;
      setState(() {
        _rows = result.items;
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

  void _showDetail(Intervention i) {
    showInterventionsDetailSheet(
      context: context,
      title: i.titreAffiche,
      children: interventionDetailRows(i),
    );
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
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InterventionsSectionHeader(
            title: 'Mon calendrier',
            subtitle: 'Planning des interventions du mois',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthLabelFr(_monthKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  trailingWidget: InterventionEtatBadge(etat: i.etat),
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
                ? InterventionsUi.accent.withValues(alpha: 0.15)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: InterventionsUi.gradientStart)
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
                      ? InterventionsUi.gradientStart
                      : AromaColors.zinc900,
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: InterventionsUi.gradientStart,
                    borderRadius: BorderRadius.circular(8),
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
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InterventionsSectionHeader(
            title: 'Mes appels de courtoisie (ADC)',
            subtitle: 'Suivi des contacts clients après intervention',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher client, site, statut…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
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
  const InterventionsTransportTab({super.key});

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
      final api = context.read<AuthProvider>().api;
      final rows = await api.listTransports();
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

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InterventionsSectionHeader(
            title: 'Mon transport',
            subtitle: 'Fiches de déplacement terrain',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher ville, raison…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
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
  const InterventionsReparationsTab({super.key});

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
      final api = context.read<AuthProvider>().api;
      final result = await api.listReparations(limit: 200);
      if (!mounted) return;
      setState(() {
        _rows = result.items;
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

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return interventionsErrorState(message: _error!, onRetry: _reload);
    }

    final rows = _filtered;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InterventionsSectionHeader(
            title: 'Mes réparations',
            subtitle: 'Suivi des équipements en réparation',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher client, réf., statut…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
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
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InterventionsSectionHeader(
            title: "Mes rapports d'interactions",
            subtitle: 'Synthèse mensuelle par client — aligné CRM web',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _summary?.moisLabel.isNotEmpty == true
                      ? _summary!.moisLabel
                      : monthLabelFr(_monthKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Interventions',
                  value: '$_totalInterventions',
                  color: InterventionsUi.gradientStart,
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
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un client…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
          ),
        ],
      ),
    );
  }
}
