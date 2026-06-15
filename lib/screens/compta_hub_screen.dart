import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/compta/compta_historique_tab.dart';
import '../widgets/compta/compta_operations_tab.dart';
import '../widgets/compta/compta_recouvrement_tab.dart';
import '../widgets/compta/compta_ui.dart';
import '../widgets/entity_scope_selector.dart';

class ComptaHubScreen extends StatefulWidget {
  const ComptaHubScreen({super.key});

  @override
  State<ComptaHubScreen> createState() => _ComptaHubScreenState();
}

class _ComptaHubScreenState extends State<ComptaHubScreen> {
  String _currentTab = 'operations';
  int _recouvrementRetardCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBadgeCounts();
  }

  Future<void> _loadBadgeCounts() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isPrivilegedStaff && !auth.canAccess('comptabilite')) return;
    try {
      final page = await auth.api.getRecouvrementPage();
      if (!mounted) return;
      setState(() => _recouvrementRetardCount = page.facturesRetard.length);
    } catch (_) {}
  }

  List<ComptaTabConfig> _tabs(AuthProvider auth) {
    final canRecouvrement =
        auth.isPrivilegedStaff || auth.canAccess('comptabilite');
    return [
      const ComptaTabConfig(
        'operations',
        'Opérations de caisse',
        Icons.receipt_long_outlined,
      ),
      const ComptaTabConfig(
        'historique',
        'Mon historique',
        Icons.history_rounded,
      ),
      if (canRecouvrement)
        ComptaTabConfig(
          'recouvrement',
          'Recouvrement',
          Icons.payments_outlined,
          count: _recouvrementRetardCount > 0 ? _recouvrementRetardCount : null,
        ),
    ];
  }

  void _selectTab(String tab) {
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = _tabs(auth);
    final moisLabel = monthLabelFr(currentMonthIso());
    final selectedTab = tabs.any((t) => t.id == _currentTab)
        ? _currentTab
        : tabs.first.id;

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ComptaHeader(subtitle: 'Comptabilité · $moisLabel'),
            const SizedBox(height: 8),
            ComptaTabPills(
              tabs: tabs,
              selected: selectedTab,
              onSelected: _selectTab,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (selectedTab) {
                'historique' => ComptaHistoriqueTab(
                    key: ValueKey('historique-${auth.currentEntityCode}'),
                  ),
                'recouvrement' => ComptaRecouvrementTab(
                    key: ValueKey('recouvrement-${auth.currentEntityCode}'),
                  ),
                _ => ComptaOperationsTab(
                    key: ValueKey('operations-${auth.currentEntityCode}'),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ComptaHeader extends StatelessWidget {
  const _ComptaHeader({required this.subtitle});

  final String subtitle;

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
              gradient: ComptaUi.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calculate_outlined,
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
                  'Espace Comptabilité',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
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
