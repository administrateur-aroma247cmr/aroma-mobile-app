import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recouvrement.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';
import 'fiche_recouvrement_screen.dart';

class RecouvrementScreen extends StatefulWidget {
  const RecouvrementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RecouvrementScreen> createState() => _RecouvrementScreenState();
}

class _RecouvrementScreenState extends State<RecouvrementScreen>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  RecouvrementPage? _data;
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
      final data = await api.getRecouvrementPage();
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

  List<FactureRecouvrementItem> _filter(List<FactureRecouvrementItem> list) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (f) =>
              f.nomClient.toLowerCase().contains(q) ||
              f.refFacture.toLowerCase().contains(q) ||
              f.id.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openFiche(FactureRecouvrementItem f) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FicheRecouvrementScreen(facture: f),
      ),
    ).then((_) => _reload());
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorBox(message: _error!, onRetry: _reload);
    }
    final data = _data!;
    final retard = _filter(data.facturesRetard);
    final attendu = _filter(data.facturesAttendu);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Montant retard',
                  value: fmtFcfa(data.montantRetard),
                  icon: Icons.warning_amber_rounded,
                  accent: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Montant attendu (mois)',
                  value: fmtFcfa(data.montantAttendu),
                  icon: Icons.schedule_rounded,
                  accent: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher client ou référence…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 20),
          Text(
            'Factures en retard (${retard.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (retard.isEmpty)
            const _EmptyHint('Aucune facture en retard.')
          else
            ...retard.map((f) => _FactureTile(facture: f, onTap: () => _openFiche(f))),
          const SizedBox(height: 24),
          Text(
            'Factures attendues — mois en cours (${attendu.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (attendu.isEmpty)
            const _EmptyHint('Aucune facture attendue ce mois.')
          else
            ...attendu.map((f) => _FactureTile(facture: f, onTap: () => _openFiche(f))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (widget.embedded) return _body();
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Le recouvrement'),
        actions: const [EntityScopeAppBarAction()],
      ),
      body: _body(),
    );
  }
}

class _FactureTile extends StatelessWidget {
  const _FactureTile({required this.facture, required this.onTap});

  final FactureRecouvrementItem facture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(facture.nomClient),
        subtitle: Text(
          '${facture.refFacture} · ${formatDateFr(facture.dateAttendu)}'
          '${facture.statut != null ? ' · ${facture.statut}' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmtFcfa(facture.montant),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (facture.joursRetard > 0)
              Text(
                '${facture.joursRetard} j retard',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            const Icon(Icons.chevron_right_rounded, size: 18),
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
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: AromaColors.zinc500)),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AromaColors.zinc500)),
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
