import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analytics.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/analytics/analytics_module_tabs.dart';
import '../widgets/analytics/analytics_strips.dart';
import '../widgets/analytics/views/analytics_commercial_view.dart';
import '../widgets/analytics/views/analytics_comptabilite_view.dart';
import '../widgets/analytics/views/analytics_controle_view.dart';
import '../widgets/analytics/views/analytics_facturation_view.dart';
import '../widgets/analytics/views/analytics_interventions_view.dart';
import '../widgets/analytics/views/analytics_recouvrement_view.dart';
import '../widgets/analytics/views/analytics_stock_view.dart';
import '../widgets/analytics/views/analytics_taches_view.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with EntityScopeReloadMixin {
  static const _periodes = ['mois', '30j', 'trimestre'];
  static const _periodeLabels = {
    'mois': 'Ce mois',
    '30j': '30 jours',
    'trimestre': 'Trimestre',
  };

  String _periode = 'mois';
  AnalyticsTab _tab = AnalyticsTab.controle;
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

  Widget _buildTabContent(AnalyticsGlobalDashboard data) {
    return switch (_tab) {
      AnalyticsTab.controle => data.controle != null
          ? AnalyticsControleView(data: data.controle!)
          : _SyntheseFallback(data: data),
      AnalyticsTab.interventions =>
        AnalyticsInterventionsView(data: data.interventions),
      AnalyticsTab.stock => AnalyticsStockView(data: data.stock),
      AnalyticsTab.comptabilite =>
        AnalyticsComptabiliteView(data: data.comptabilite),
      AnalyticsTab.facturation =>
        AnalyticsFacturationView(data: data.facturation),
      AnalyticsTab.recouvrement =>
        AnalyticsRecouvrementView(data: data.recouvrement),
      AnalyticsTab.commercial =>
        AnalyticsCommercialView(data: data.commercial),
      AnalyticsTab.taches => AnalyticsTachesView(data: data.taches),
    };
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Analytics KPI'),
              actions: const [EntityScopeAppBarAction()],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _AnalyticsError(message: _error!, onRetry: _reload)
              : _data == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          if (_data!.parc != null) ...[
                            AnalyticsParcStrip(data: _data!.parc!),
                            const SizedBox(height: 12),
                          ],
                          if (_data!.relationClient != null) ...[
                            AnalyticsRelationStrip(data: _data!.relationClient!),
                            const SizedBox(height: 12),
                          ],
                          SegmentedButton<String>(
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
                          const SizedBox(height: 8),
                          Text(
                            _data!.periodeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AromaColors.zinc500,
                                ),
                          ),
                          const SizedBox(height: 12),
                          AnalyticsModuleTabs(
                            activeTab: _tab,
                            onTabChanged: (t) => setState(() => _tab = t),
                            child: _buildTabContent(_data!),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SyntheseFallback extends StatelessWidget {
  const _SyntheseFallback({required this.data});

  final AnalyticsGlobalDashboard data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Données de contrôle indisponibles — synthèse globale :',
          style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
        ),
        const SizedBox(height: 12),
        if (data.synthese.highlights.isNotEmpty) ...[
          const Text(
            'Synthèse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final h in data.synthese.highlights)
            Card(
              child: ListTile(
                title: Text(h.label),
                subtitle: h.sublabel != null ? Text(h.sublabel!) : null,
                trailing: Text(
                  h.value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
        if (data.synthese.zones.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Zones de vigilance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final z in data.synthese.zones)
            Card(
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
                    for (final m in z.metrics)
                      Padding(
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
                  ],
                ),
              ),
            ),
        ],
      ],
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

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.message, required this.onRetry});

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
