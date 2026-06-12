import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analytics.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> with EntityScopeReloadMixin {
  static const _periodes = ['mois', '30j', 'trimestre'];
  static const _periodeLabels = {
    'mois': 'Ce mois',
    '30j': '30 jours',
    'trimestre': 'Trimestre',
  };

  String _periode = 'mois';
  bool _loading = true;
  String? _error;
  AnalyticsGlobalDashboard? _data;

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
      final data = await api.getAnalyticsGlobal(_periode);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Analytics KPI'),
        actions: const [EntityScopeAppBarAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: _periodes
                  .map(
                    (p) => ButtonSegment(
                      value: p,
                      label: Text(_periodeLabels[p] ?? p),
                    ),
                  )
                  .toList(),
              selected: {_periode},
              onSelectionChanged: (s) async {
                setState(() => _periode = s.first);
                await _reload();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _KpiError(message: _error!, onRetry: _reload)
                : _data == null
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          _data!.periodeLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_data!.synthese.highlights.isNotEmpty) ...[
                          _SectionTitle('Synthèse'),
                          const SizedBox(height: 8),
                          ..._data!.synthese.highlights.map(
                            (h) => Card(
                              child: ListTile(
                                title: Text(h.label),
                                subtitle: h.sublabel != null
                                    ? Text(h.sublabel!)
                                    : null,
                                trailing: Text(
                                  h.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_data!.parc != null) ...[
                          _SectionTitle('Parc'),
                          const SizedBox(height: 8),
                          _MetricGrid(cells: [
                            _MetricCell(
                              'Clients actifs',
                              '${_data!.parc!.clientsActifs}',
                            ),
                            _MetricCell('Sites', '${_data!.parc!.nbSites}'),
                            _MetricCell(
                              'Diffuseurs',
                              '${_data!.parc!.nbDiffuseurs}',
                            ),
                          ]),
                          const SizedBox(height: 16),
                        ],
                        _SectionTitle('Interventions'),
                        const SizedBox(height: 8),
                        _MetricGrid(cells: [
                          _MetricCell(
                            'Total',
                            '${_data!.interventions.total}',
                          ),
                          _MetricCell(
                            'Période',
                            '${_data!.interventions.periode}',
                          ),
                          _MetricCell(
                            'Taux clôture',
                            '${_data!.interventions.tauxCloturePct.toStringAsFixed(1)} %',
                          ),
                          _MetricCell(
                            'Délai moyen (j)',
                            _data!.interventions.delaiMoyenJours
                                .toStringAsFixed(1),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _SectionTitle('Stock'),
                        const SizedBox(height: 8),
                        _MetricGrid(cells: [
                          _MetricCell(
                            'Sorties huile (ml)',
                            _data!.stock.sortiesHuileMl.toStringAsFixed(0),
                          ),
                          _MetricCell(
                            'Alertes conso',
                            '${_data!.stock.alertesConso}',
                          ),
                          _MetricCell(
                            'BC ouverts',
                            '${_data!.stock.bonsCommandeOuverts}',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _SectionTitle('Facturation & recouvrement'),
                        const SizedBox(height: 8),
                        _MetricGrid(cells: [
                          _MetricCell(
                            'Factures période',
                            '${_data!.facturation.facturesPeriode}',
                          ),
                          _MetricCell(
                            'Montant facturé',
                            fmtFcfa(_data!.facturation.montantFactureFcfa),
                          ),
                          _MetricCell(
                            'Encours',
                            fmtFcfa(_data!.recouvrement.montantEncours),
                          ),
                          _MetricCell(
                            'Taux recouvrement',
                            '${_data!.recouvrement.tauxRecouvrementPct.toStringAsFixed(1)} %',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _SectionTitle('Commercial'),
                        const SizedBox(height: 8),
                        _MetricGrid(cells: [
                          _MetricCell(
                            'Ventes période',
                            fmtFcfa(_data!.commercial.ventesPeriodeFcfa),
                          ),
                          _MetricCell(
                            'Clients actifs',
                            '${_data!.commercial.nbClientsActifs}',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _SectionTitle('Tâches'),
                        const SizedBox(height: 8),
                        _MetricGrid(cells: [
                          _MetricCell(
                            'Total période',
                            '${_data!.taches.totalPeriode}',
                          ),
                          _MetricCell(
                            'Terminées',
                            '${_data!.taches.termineesPeriode}',
                          ),
                          _MetricCell(
                            'Taux complétion',
                            '${_data!.taches.tauxCompletionPct.toStringAsFixed(1)} %',
                          ),
                        ]),
                        if (_data!.synthese.zones.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionTitle('Zones de vigilance'),
                          const SizedBox(height: 8),
                          ..._data!.synthese.zones.map(
                            (z) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _StatusDot(status: z.status),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            z.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...z.metrics.map(
                                      (m) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(m.label)),
                                            Text(
                                              m.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'alert' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.green,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
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
  }
}

class _KpiError extends StatelessWidget {
  const _KpiError({required this.message, required this.onRetry});

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
