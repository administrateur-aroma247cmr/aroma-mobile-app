import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recouvrement.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import 'compta_ui.dart';

class ComptaPilotageTab extends StatefulWidget {
  const ComptaPilotageTab({
    super.key,
    required this.onNavigate,
    this.caisseEnAttenteCount = 0,
  });

  final ValueChanged<String> onNavigate;
  final int caisseEnAttenteCount;

  @override
  State<ComptaPilotageTab> createState() => _ComptaPilotageTabState();
}

class _ComptaPilotageTabState extends State<ComptaPilotageTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  RecouvrementKpiBundle? _bundle;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    final canRecouvrement =
        auth.isPrivilegedStaff || auth.canAccess('comptabilite');

    if (!canRecouvrement) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await auth.api.getRecouvrementKpiBundle();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
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
    final auth = context.watch<AuthProvider>();
    final canRecouvrement =
        auth.isPrivilegedStaff || auth.canAccess('comptabilite');
    final moisLabel = monthLabelFr(currentMonthIso());

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              gradient: ComptaUi.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ComptaUi.accent.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilotage · $moisLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),
                if (canRecouvrement && _bundle != null) ...[
                  Row(
                    children: [
                      _HeroKpi(
                        label: 'Recettes',
                        value: fmtFcfa(_bundle!.recetteMois),
                      ),
                      const SizedBox(width: 10),
                      _HeroKpi(
                        label: 'Dépenses',
                        value: fmtFcfa(_bundle!.depenseMois),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _HeroKpi(
                    label: 'Reste à recouvrer',
                    value: fmtFcfa(_bundle!.page.montantSolde),
                    fullWidth: true,
                  ),
                ] else if (_error != null) ...[
                  Text(
                    'Récap indisponible pour le moment.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Opérations caisse et suivi des demandes.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canRecouvrement && _bundle != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                ComptaStatPill(
                  label: 'Factures retard',
                  value: '${_bundle!.nbFacturesRetard}',
                  color: const Color(0xFFB91C1C),
                ),
                const SizedBox(width: 10),
                ComptaStatPill(
                  label: 'Montant retard',
                  value: fmtFcfa(_bundle!.page.montantRetard),
                  color: const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                ComptaStatPill(
                  label: 'Recouvré (mois)',
                  value: fmtFcfa(_bundle!.montantRecouvreMois),
                  color: ComptaUi.gradientStart,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const ComptaSectionHeader(
            title: 'Actions rapides',
            subtitle: 'Accédez aux modules comptables',
          ),
          const SizedBox(height: 12),
          ComptaQuickActionCard(
            title: 'Opérations de caisse',
            subtitle: 'Demandes à payer, validation et historique',
            icon: Icons.account_balance_wallet_outlined,
            badge: widget.caisseEnAttenteCount > 0
                ? '${widget.caisseEnAttenteCount}'
                : null,
            accent: const Color(0xFFF97316),
            onTap: () => widget.onNavigate('caisse'),
          ),
          const SizedBox(height: 10),
          if (canRecouvrement)
            ComptaQuickActionCard(
              title: 'Le recouvrement',
              subtitle: _bundle != null
                  ? '${_bundle!.nbFacturesRetard} facture(s) en retard · '
                      '${_bundle!.nbFacturesAttendu} attendue(s)'
                  : 'Factures en retard et attendues',
              icon: Icons.payments_outlined,
              badge: _bundle != null && _bundle!.nbFacturesRetard > 0
                  ? '${_bundle!.nbFacturesRetard}'
                  : null,
              onTap: () => widget.onNavigate('recouvrement'),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: ComptaUi.gradientStart,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Facturation, calendrier comptable et prévisions arrivent '
                    'prochainement. Les opérations avancées restent sur le CRM web.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ComptaUi.gradientStart.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: child);
    return Expanded(child: child);
  }
}
