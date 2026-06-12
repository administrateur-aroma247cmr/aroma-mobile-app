import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rh_dashboard.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';

class RhRecapScreen extends StatefulWidget {
  const RhRecapScreen({super.key, this.embedded = false});

  final bool embedded;

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
    _selectedCollabId = auth.collaborateurId;
    if (auth.isPrivilegedStaff) {
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
        auth.isPrivilegedStaff && _collaborateurs.length > 1;

    final body = _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _RhError(message: _error!, onRetry: _reload)
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (canPickCollab)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCollabId,
                            items: _collaborateurs
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              setState(() => _selectedCollabId = v);
                              await _reload();
                            },
                          ),
                        ),
                      ),
                    ),
                  if (canPickCollab) const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Mois'),
                      subtitle: Text(monthLabelFr(_mois)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickMonth,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Mon univers — ${_dash?.moisLabelFr ?? monthLabelFr(_mois)}'),
                  const SizedBox(height: 8),
                  _MetricGrid(
                    cells: _dash == null
                        ? const []
                        : [
                            _MetricCell('Retard', '${_dash!.retardOccurrences}'),
                            _MetricCell('Absence', '${_dash!.absenceCount}'),
                            _MetricCell(
                              'Absence pointage',
                              '${_dash!.absencePointage}',
                            ),
                            _MetricCell(
                              'Absence samedi',
                              '${_dash!.absenceSamedi}',
                            ),
                            _MetricCell(
                              'Vacances (jours)',
                              '${_dash!.vacancesJours}',
                            ),
                            _MetricCell(
                              "Demandes d'explication",
                              '${_dash!.demandesExplication}',
                            ),
                            _MetricCell(
                              'Avance salaire',
                              fmtFcfa(_dash!.avanceSalaire),
                            ),
                            _MetricCell(
                              'Retenu compta',
                              fmtFcfa(_dash!.retenuCompta),
                            ),
                            _MetricCell(
                              'Factures non conformes',
                              '${_dash!.facturesNonConformes}',
                            ),
                            _MetricCell(
                              '5% Rémunération (boutique)',
                              _dash!.boutiqueSeuilAtteint
                                  ? fmtFcfa(
                                      _dash!
                                          .remuneration5pctBoutiqueIndividuelle,
                                    )
                                  : '—',
                            ),
                            _MetricCell(
                              "Nombre d'avertissements",
                              '${_dash!.nombreAvertissements}',
                            ),
                            _MetricCell(
                              '5% Vente directe',
                              fmtFcfa(_dash!.commission5pctVenteDirecte),
                            ),
                            _MetricCell(
                              'Prime rentabilité',
                              fmtFcfa(_dash!.primeRentabilite),
                            ),
                          ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    _historique?.dateReferenceLabel != null
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
                            ),
                            _MetricCell(
                              "Demandes d'explication",
                              '${_historique!.demandesExplication}',
                            ),
                            _MetricCell(
                              'Avertissements',
                              '${_historique!.avertissements}',
                            ),
                            _MetricCell(
                              'Prime totale',
                              fmtFcfa(_historique!.primeTotale),
                            ),
                            _MetricCell(
                              'Jours congé total',
                              '${_historique!.joursCongeTotal}',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AromaColors.zinc900,
      ),
    );
  }
}

class _MetricCell {
  const _MetricCell(this.label, this.value);

  final String label;
  final String value;
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
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: cells.length,
          itemBuilder: (context, i) {
            final cell = cells[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cell.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      cell.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RhError extends StatelessWidget {
  const _RhError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
