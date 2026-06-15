import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analytics.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/kpi_chart_widgets.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen>
    with SingleTickerProviderStateMixin, EntityScopeReloadMixin {
  static const _periodes = ['mois', '30j', 'trimestre'];
  static const _periodeLabels = {
    'mois': 'Ce mois',
    '30j': '30 jours',
    'trimestre': 'Trimestre',
  };

  late TabController _tabs;
  String _periode = 'mois';
  bool _loading = true;
  String? _error;
  AnalyticsGlobalDashboard? _data;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Contrôle'),
            Tab(text: 'Interventions'),
            Tab(text: 'Stock'),
            Tab(text: 'Compta'),
            Tab(text: 'Facturation'),
            Tab(text: 'Recouvrement'),
            Tab(text: 'Commercial'),
            Tab(text: 'Tâches'),
          ],
        ),
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
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _ControleTab(data: _data!),
                      _InterventionsTab(data: _data!.interventions),
                      _StockTab(data: _data!.stock),
                      _ComptaTab(data: _data!.comptabilite),
                      _FacturationTab(data: _data!.facturation),
                      _RecouvrementTab(data: _data!.recouvrement),
                      _CommercialTab(data: _data!.commercial),
                      _TachesTab(data: _data!.taches),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ControleTab extends StatelessWidget {
  const _ControleTab({required this.data});

  final AnalyticsGlobalDashboard data;

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            data.periodeLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (data.parc != null) ...[
            const SizedBox(height: 12),
            _MetricGrid(cells: [
              _MetricCell('Clients actifs', '${data.parc!.clientsActifs}'),
              _MetricCell('Sites', '${data.parc!.nbSites}'),
              _MetricCell('Diffuseurs', '${data.parc!.nbDiffuseurs}'),
            ]),
          ],
          if (data.synthese.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Synthèse'),
            ...data.synthese.highlights.map(
              (h) => Card(
                child: ListTile(
                  title: Text(h.label),
                  subtitle: h.sublabel != null ? Text(h.sublabel!) : null,
                  trailing: Text(
                    h.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
          if (data.synthese.zones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Zones de vigilance'),
            ...data.synthese.zones.map(
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
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...z.metrics.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.label)),
                              Text(
                                m.value,
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}

class _InterventionsTab extends StatelessWidget {
  const _InterventionsTab({required this.data});
  final AnalyticsInterventionsKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('Période', '${data.periode}'),
          _MetricCell('Total', '${data.total}'),
          _MetricCell('Taux clôture', '${data.tauxCloturePct.toStringAsFixed(1)} %'),
          _MetricCell('Délai moyen', '${data.delaiMoyenJours.toStringAsFixed(1)} j'),
          _MetricCell('Réparations', '${data.reparationsOuvertes}'),
          _MetricCell('Refill 1/2', '${data.refill1} / ${data.refill2}'),
        ]),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Taux de clôture',
          pct: data.tauxCloturePct,
          sublabel: 'Planifiées → clôturées',
        ),
        const SizedBox(height: 12),
        KpiBarChartCard(title: 'Par type', data: data.parType),
        const SizedBox(height: 12),
        KpiPieChartCard(title: 'Par état', data: data.parEtat),
        const SizedBox(height: 12),
        KpiLineChartCard(title: 'Évolution mensuelle', data: data.tendanceMensuelle),
      ],
    );
  }
}

class _StockTab extends StatelessWidget {
  const _StockTab({required this.data});
  final AnalyticsStockKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('Sorties huile (ml)', data.sortiesHuileMl.toStringAsFixed(0)),
          _MetricCell('Valeur stock', fmtFcfa(data.valeurStockFcfa)),
          _MetricCell('Alertes conso', '${data.alertesConso}'),
          _MetricCell('BC ouverts', '${data.bonsCommandeOuverts}'),
        ]),
        const SizedBox(height: 12),
        KpiBarChartCard(title: 'Par entrepôt', data: data.parEntrepot),
        const SizedBox(height: 12),
        KpiLineChartCard(title: 'Tendance sorties', data: data.tendanceSorties),
      ],
    );
  }
}

class _ComptaTab extends StatelessWidget {
  const _ComptaTab({required this.data});
  final AnalyticsComptabiliteKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('CA crédits', fmtFcfa(data.caCredits ?? data.montantTotalFcfa)),
          _MetricCell('Charges débit', fmtFcfa(data.chargesDebits)),
          _MetricCell('Marge', '${data.margePct.toStringAsFixed(1)} %'),
          _MetricCell('Écritures validées', '${data.ecrituresValideesPct.toStringAsFixed(0)} %'),
        ]),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Écritures validées',
          pct: data.ecrituresValideesPct,
        ),
        const SizedBox(height: 12),
        KpiBarChartCard(title: 'CA par site', data: data.parSite),
        const SizedBox(height: 12),
        KpiLineChartCard(title: 'Tendance CA', data: data.tendanceCa),
      ],
    );
  }
}

class _FacturationTab extends StatelessWidget {
  const _FacturationTab({required this.data});
  final AnalyticsFacturationKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('CA facturé', fmtFcfa(data.caFacture > 0 ? data.caFacture : data.montantFactureFcfa)),
          _MetricCell('Dette totale', fmtFcfa(data.detteTotale)),
          _MetricCell('Factures retard', '${data.facturesRetard}'),
          _MetricCell('Taux recouvrement', '${data.tauxRecouvrementPct.toStringAsFixed(1)} %'),
        ]),
        const SizedBox(height: 12),
        KpiPieChartCard(title: 'Par statut', data: data.parStatut),
        const SizedBox(height: 12),
        KpiLineChartCard(title: 'Tendance CA (6 mois)', data: data.tendanceCa),
      ],
    );
  }
}

class _RecouvrementTab extends StatelessWidget {
  const _RecouvrementTab({required this.data});
  final AnalyticsRecouvrementKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('Encours', fmtFcfa(data.montantEncours)),
          _MetricCell('Retard', fmtFcfa(data.montantRetard)),
          _MetricCell('Attendu', fmtFcfa(data.montantAttendu)),
          _MetricCell('Relances', '${data.nbRelancesTotal}'),
          _MetricCell('Retard moyen', '${data.joursRetardMoyen.toStringAsFixed(0)} j'),
          _MetricCell('Factures retard', '${data.nbFacturesRetard}'),
        ]),
        const SizedBox(height: 12),
        KpiBarChartCard(title: 'Retard par ancienneté', data: data.parTrancheRetard),
        const SizedBox(height: 12),
        KpiBarChartCard(title: 'Top clients retard', data: data.topFacturesRetard),
      ],
    );
  }
}

class _CommercialTab extends StatelessWidget {
  const _CommercialTab({required this.data});
  final AnalyticsCommercialKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('Ventes période', fmtFcfa(data.ventesPeriodeFcfa)),
          _MetricCell('Clients actifs', '${data.nbClientsActifs}'),
        ]),
      ],
    );
  }
}

class _TachesTab extends StatelessWidget {
  const _TachesTab({required this.data});
  final AnalyticsTachesKpi data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(cells: [
          _MetricCell('Total période', '${data.totalPeriode}'),
          _MetricCell('Terminées', '${data.termineesPeriode}'),
          _MetricCell('En retard', '${data.enRetard}'),
          _MetricCell('Observations', '${data.observations}'),
        ]),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Taux complétion',
          pct: data.tauxCompletionPct,
          sublabel: '${data.termineesPeriode} / ${data.totalPeriode} terminées',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AromaColors.zinc900,
            ),
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
                  style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
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
