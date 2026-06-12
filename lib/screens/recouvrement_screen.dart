import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recouvrement.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';

class RecouvrementScreen extends StatefulWidget {
  const RecouvrementScreen({super.key});

  @override
  State<RecouvrementScreen> createState() => _RecouvrementScreenState();
}

class _RecouvrementScreenState extends State<RecouvrementScreen>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  RecouvrementKpiBundle? _data;

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
      final data = await api.getRecouvrementKpiBundle();
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
        title: const Text('Recouvrement'),
        actions: const [EntityScopeAppBarAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorBox(message: _error!, onRetry: _reload)
          : _data == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Synthèse du mois — ${monthLabelFr(currentMonthIso())}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _KpiCard(
                    title: 'Montant solde à recouvrer',
                    value: fmtFcfa(_data!.montantEncours),
                    subtitle:
                        '${_data!.nbFacturesARecouvrer} facture(s) à recouvrer',
                    icon: Icons.account_balance_outlined,
                    accent: Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  _KpiCard(
                    title: 'Solde recouvré à ce jour (mois)',
                    value: fmtFcfa(_data!.montantRecouvreMois),
                    subtitle:
                        '${_data!.nbRelancesTotal} APL · '
                        'Historique ${fmtFcfa(_data!.montantRecouvreMois)} · '
                        '${_data!.nbClientsARecouvrer} client(s) à recouvrer',
                    icon: Icons.trending_up_rounded,
                    accent: Colors.green.shade700,
                  ),
                  const SizedBox(height: 12),
                  _KpiCard(
                    title: 'Montant factures à payer (ce mois)',
                    value: fmtFcfa(
                      _data!.depenseMois ?? _data!.demandesMontantMois ?? 0,
                    ),
                    subtitle: 'Sorties / demandes à payer du mois',
                    icon: Icons.receipt_long_outlined,
                    accent: Colors.orange.shade800,
                  ),
                  const SizedBox(height: 12),
                  _KpiCard(
                    title: 'Montant encaissé ce mois',
                    value: fmtFcfa(_data!.recetteMois ?? 0),
                    subtitle: 'Recettes / encaissements du mois',
                    icon: Icons.payments_outlined,
                    accent: Colors.indigo.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Détail factures en retard',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_data!.page.facturesRetard.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucune facture en retard.',
                          style: TextStyle(color: AromaColors.zinc500),
                        ),
                      ),
                    )
                  else
                    ..._data!.page.facturesRetard.take(20).map(
                      (f) => Card(
                        child: ListTile(
                          title: Text(f.nomClient),
                          subtitle: Text(
                            '${f.refFacture} · ${formatDateFr(f.dateAttendu)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fmtFcfa(f.montant),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (f.joursRetard > 0)
                                Text(
                                  '${f.joursRetard} j retard',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AromaColors.zinc500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

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
