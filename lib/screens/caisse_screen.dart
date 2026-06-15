import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caisse_metrics.dart';
import '../models/demande_a_payer.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/caisse/caisse_ui.dart';
import '../widgets/caisse_demande_form_sheet.dart';
import '../widgets/entity_scope_selector.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen>
    with EntityScopeReloadMixin {
  String _currentTab = 'demandes';
  bool _loading = true;
  String? _error;
  List<DemandeAPayer> _demandes = [];
  List<DemandeAPayer> _demandesValidation = [];
  CaisseMetrics? _metrics;
  MaCaisseAccess? _access;

  static const _tabs = [
    CaisseTabConfig(
      'demandes',
      'Mes demandes à payer',
      Icons.receipt_long_outlined,
    ),
    CaisseTabConfig(
      'ma_caisse',
      'Ma caisse',
      Icons.storefront_outlined,
    ),
    CaisseTabConfig(
      'recap',
      'Mon récapitulatif',
      Icons.summarize_outlined,
    ),
  ];

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
      final access = await api.getMaCaisseAccess();
      final canMaCaisse = auth.canAccessCaisseMaPage(access);
      final futures = <Future<dynamic>>[
        api.listDemandesAPayer(auteurMoi: true),
        if (canMaCaisse)
          api.listDemandesAPayer(
            statut: 'Soumis en attente de validations',
          ),
        if (auth.isExecutive) api.getCaisseMetrics(),
      ];
      final results = await Future.wait(futures);
      if (!mounted) return;
      var idx = 0;
      final demandes = results[idx++] as List<DemandeAPayer>;
      List<DemandeAPayer> validation = [];
      if (canMaCaisse && idx < results.length) {
        validation = results[idx++] as List<DemandeAPayer>;
      }
      CaisseMetrics? metrics;
      if (auth.isExecutive && idx < results.length) {
        metrics = results[idx] as CaisseMetrics;
      }
      setState(() {
        _demandes = demandes;
        _demandesValidation = validation;
        _access = access;
        _metrics = metrics;
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

  Future<void> _openDemandeForm({DemandeAPayer? demande}) async {
    final auth = context.read<AuthProvider>();
    if (demande == null && !auth.canCreateCaisseDemande) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Création non autorisée.')),
      );
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CaisseDemandeFormSheet(demande: demande),
    );
    if (ok == true) await _reload();
  }

  Widget _tabContent(AuthProvider auth) {
    final canMaCaisse = auth.canAccessCaisseMaPage(_access);
    final showMaCaisseHint = canMaCaisse;

    return switch (_currentTab) {
      'ma_caisse' => _MaCaisseTab(
          canAccess: canMaCaisse,
          demandes: _demandesValidation,
          isDesignatedCaissier: _access?.isDesignatedCaissier == true,
          onRefresh: _reload,
        ),
      'recap' => _RecapTab(
          isExecutive: auth.isExecutive,
          metrics: _metrics,
          recapPerso: _recapPerso(),
          showMaCaisseHint: showMaCaisseHint,
          isDesignatedCaissier: _access?.isDesignatedCaissier == true,
        ),
      _ => _DemandesTab(
          demandes: _demandes,
          onRefresh: _reload,
          canEdit: auth.canCreateCaisseDemande,
          onEdit: (d) => _openDemandeForm(demande: d),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      floatingActionButton: auth.canCreateCaisseDemande && _currentTab == 'demandes'
          ? FloatingActionButton.extended(
              onPressed: () => _openDemandeForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle demande'),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CaisseHeader(),
            const SizedBox(height: 8),
            CaisseTabPills(
              tabs: _tabs,
              selected: _currentTab,
              onSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _CaisseError(message: _error!, onRetry: _reload)
                  : _tabContent(auth),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaisseHeader extends StatelessWidget {
  const _CaisseHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: CaisseUi.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma caisse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const Text(
                  'Demandes à payer, opérations et récapitulatif',
                  style: TextStyle(
                    fontSize: 13,
                    color: AromaColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          const EntityScopeAppBarAction(),
        ],
      ),
    );
  }
}

class _MaCaisseTab extends StatelessWidget {
  const _MaCaisseTab({
    required this.canAccess,
    required this.demandes,
    required this.isDesignatedCaissier,
    required this.onRefresh,
  });

  final bool canAccess;
  final List<DemandeAPayer> demandes;
  final bool isDesignatedCaissier;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!canAccess) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Accès réservé au caissier désigné ou à la direction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AromaColors.zinc500),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              isDesignatedCaissier
                  ? 'Vous êtes caissier désigné. Ouverture/fermeture de caisse : utilisez le CRM web pour les opérations complètes.'
                  : 'Vue opérationnelle caisse. Les sessions ouverture/fermeture restent sur le CRM web.',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Demandes en attente de validation (${demandes.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (demandes.isEmpty)
          const Text(
            'Aucune demande en attente.',
            style: TextStyle(color: AromaColors.zinc500),
          )
        else
          ...demandes.map(
            (d) => Card(
              child: ListTile(
                title: Text(d.raisonBonCommande),
                subtitle: Text('${d.client} · ${formatDateFr(d.dateADecaisser)}'),
                trailing: Text(
                  fmtFcfa(d.montantDemande),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DemandesTab extends StatelessWidget {
  const _DemandesTab({
    required this.demandes,
    required this.onRefresh,
    required this.canEdit,
    required this.onEdit,
  });

  final List<DemandeAPayer> demandes;
  final Future<void> Function() onRefresh;
  final bool canEdit;
  final void Function(DemandeAPayer) onEdit;

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
          final isBrouillon = (d.statut ?? '').contains('Brouillon');
          return Card(
            child: ListTile(
              onTap: canEdit && isBrouillon ? () => onEdit(d) : null,
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
