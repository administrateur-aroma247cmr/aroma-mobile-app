import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caisse_metrics.dart';
import '../models/demande_a_payer.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen>
    with SingleTickerProviderStateMixin, EntityScopeReloadMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  List<DemandeAPayer> _demandes = [];
  CaisseMetrics? _metrics;
  MaCaisseAccess? _access;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      final futures = <Future<dynamic>>[
        api.listDemandesAPayer(auteurMoi: true),
        api.getMaCaisseAccess(),
      ];
      if (auth.isExecutive) {
        futures.add(api.getCaisseMetrics());
      }
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _demandes = results[0] as List<DemandeAPayer>;
        _access = results[1] as MaCaisseAccess;
        _metrics = auth.isExecutive && results.length > 2
            ? results[2] as CaisseMetrics
            : null;
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

  CaisseRecapPerso _recapPerso() {
    var brouillon = 0;
    var enAttente = 0;
    var paye = 0;
    var montantPaye = 0.0;
    for (final d in _demandes) {
      final s = (d.statut ?? '').trim();
      if (s == 'Paye') {
        paye++;
        montantPaye += d.montantDemande;
      } else if (s == 'Brouillon') {
        brouillon++;
      } else if (s.contains('attente') || s.contains('Soumis')) {
        enAttente++;
      }
    }
    return CaisseRecapPerso(
      total: _demandes.length,
      brouillon: brouillon,
      enAttente: enAttente,
      paye: paye,
      montantPayeFcfa: montantPaye,
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();
    final showMaCaisseHint =
        auth.isCaisseMaPageDirection || (_access?.canAccess == true);

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Caisse'),
        actions: const [EntityScopeAppBarAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Mes demandes'),
            Tab(
              text: auth.isExecutive
                  ? 'Pilotage'
                  : 'Mon récapitulatif',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _CaisseError(message: _error!, onRetry: _reload)
          : TabBarView(
              controller: _tabs,
              children: [
                _DemandesTab(
                  demandes: _demandes,
                  onRefresh: _reload,
                ),
                _RecapTab(
                  isExecutive: auth.isExecutive,
                  metrics: _metrics,
                  recapPerso: _recapPerso(),
                  showMaCaisseHint: showMaCaisseHint,
                  isDesignatedCaissier: _access?.isDesignatedCaissier == true,
                ),
              ],
            ),
    );
  }
}

class _DemandesTab extends StatelessWidget {
  const _DemandesTab({required this.demandes, required this.onRefresh});

  final List<DemandeAPayer> demandes;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (demandes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Aucune demande à payer.',
                style: TextStyle(color: AromaColors.zinc500),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demandes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = demandes[i];
          return Card(
            child: ListTile(
              title: Text(d.raisonBonCommande),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.client),
                  Text(
                    formatDateFr(d.dateADecaisser),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtFcfa(d.montantDemande),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    d.statut ?? '—',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecapTab extends StatelessWidget {
  const _RecapTab({
    required this.isExecutive,
    required this.metrics,
    required this.recapPerso,
    required this.showMaCaisseHint,
    required this.isDesignatedCaissier,
  });

  final bool isExecutive;
  final CaisseMetrics? metrics;
  final CaisseRecapPerso recapPerso;
  final bool showMaCaisseHint;
  final bool isDesignatedCaissier;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isExecutive && metrics != null) ...[
          _PilotageBanner(metrics: metrics!),
          const SizedBox(height: 16),
        ],
        Text(
          isExecutive ? 'Mes demandes (résumé)' : 'Mon récapitulatif',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _MetricGrid(cells: [
          _MetricCell('Total demandes', '${recapPerso.total}'),
          _MetricCell('Brouillons', '${recapPerso.brouillon}'),
          _MetricCell('En attente', '${recapPerso.enAttente}'),
          _MetricCell('Payées', '${recapPerso.paye}'),
          _MetricCell('Montant payé', fmtFcfa(recapPerso.montantPayeFcfa)),
        ]),
        if (showMaCaisseHint) ...[
          const SizedBox(height: 20),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDesignatedCaissier
                          ? 'Vous êtes caissier désigné aujourd’hui. Les opérations d’ouverture/fermeture restent disponibles sur le CRM web.'
                          : 'Les opérations caisse avancées (ouverture, fermeture, validation) sont disponibles sur le CRM web.',
                      style: TextStyle(color: Colors.amber.shade900),
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

class _PilotageBanner extends StatelessWidget {
  const _PilotageBanner({required this.metrics});

  final CaisseMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF78350F)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilotage caisse — ${formatDateFr(metrics.dateJour)}',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _PilotageRow(
            'Solde caisse actuel',
            fmtFcfa(metrics.soldeCaisseActuelFcfa),
          ),
          _PilotageRow(
            'Mouvements du jour',
            fmtFcfa(metrics.netMouvementsCaisseAujourdhuiFcfa),
          ),
          _PilotageRow(
            'Encaissement jour',
            fmtFcfa(metrics.encaissementJourFcfa),
          ),
          _PilotageRow(
            'Attente fin journée',
            fmtFcfa(metrics.attenteFinJourneeFcfa),
          ),
          if (metrics.sessionCaisseOuverteAujourdhui == true)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Session caisse ouverte',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _PilotageRow extends StatelessWidget {
  const _PilotageRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
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

class _CaisseError extends StatelessWidget {
  const _CaisseError({required this.message, required this.onRetry});

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
