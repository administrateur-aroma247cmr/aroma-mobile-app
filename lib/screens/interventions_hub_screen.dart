import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/format_utils.dart';
import '../utils/technician_view.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/interventions/interventions_tabs.dart';
import '../widgets/interventions/interventions_ui.dart';

class InterventionsHubScreen extends StatefulWidget {
  const InterventionsHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InterventionsHubScreen> createState() => _InterventionsHubScreenState();
}

class _InterventionsHubScreenState extends State<InterventionsHubScreen> {
  String _currentTab = 'interventions';

  static const _tabs = [
    InterventionsTabConfig(
      'interventions',
      'Mes interventions',
      Icons.build_outlined,
    ),
    InterventionsTabConfig(
      'calendrier',
      'Mon calendrier',
      Icons.calendar_month_outlined,
    ),
    InterventionsTabConfig(
      'adc',
      'ADC',
      Icons.phone_in_talk_outlined,
    ),
    InterventionsTabConfig(
      'transport',
      'Mon transport',
      Icons.local_shipping_outlined,
    ),
    InterventionsTabConfig(
      'reparations',
      'Mes réparations',
      Icons.handyman_outlined,
    ),
    InterventionsTabConfig(
      'rapports',
      'Rapports',
      Icons.description_outlined,
    ),
  ];

  static const _technicianTabIds = {
    'interventions',
    'calendrier',
    'transport',
    'reparations',
  };

  void _selectTab(String tab) {
    setState(() => _currentTab = tab);
  }

  List<InterventionsTabConfig> _tabsFor(bool technicianView) {
    if (!technicianView) return _tabs;
    return _tabs.where((t) => _technicianTabIds.contains(t.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final technicianView = isTechnicianFieldView(auth);
    final moisLabel = monthLabelFr(currentMonthIso());
    final tabs = _tabsFor(technicianView);
    final selectedTab =
        tabs.any((t) => t.id == _currentTab) ? _currentTab : tabs.first.id;

    return Scaffold(
      backgroundColor: InterventionsUi.canvasSoft,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded)
              _InterventionsHeroHeader(
                subtitle: technicianView
                    ? 'Terrain · $moisLabel'
                    : 'Planning · $moisLabel',
              ),
            const SizedBox(height: 14),
            InterventionsTabPills(
              tabs: tabs,
              selected: selectedTab,
              onSelected: _selectTab,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: InterventionsUi.canvasSoft,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: switch (selectedTab) {
                    'calendrier' => InterventionsCalendarTab(
                        key: ValueKey(
                          'calendrier-${auth.currentEntityCode}-$technicianView',
                        ),
                        technicianFieldView: technicianView,
                        fieldActions: hasTechnicianFieldActions(auth),
                      ),
                    'adc' => InterventionsAdcTab(
                        key: ValueKey('adc-${auth.currentEntityCode}'),
                      ),
                    'transport' => InterventionsTransportTab(
                        key: ValueKey(
                          'transport-${auth.currentEntityCode}-$technicianView',
                        ),
                        technicianFieldView: technicianView,
                      ),
                    'reparations' => InterventionsReparationsTab(
                        key: ValueKey(
                          'reparations-${auth.currentEntityCode}-$technicianView',
                        ),
                        technicianFieldView: technicianView,
                      ),
                    'rapports' => InterventionsRapportsTab(
                        key: ValueKey('rapports-${auth.currentEntityCode}'),
                      ),
                    _ => InterventionsListTab(
                        key: ValueKey(
                          'interventions-${auth.currentEntityCode}-'
                          '${filterInterventionsByTechnicianAssignment(auth)}-'
                          '${hasInterventionsModuleAccess(auth)}',
                        ),
                        fieldActions: hasTechnicianFieldActions(auth),
                        filterByAssignment:
                            filterInterventionsByTechnicianAssignment(auth),
                        technicianDisplay:
                            isTechnicianFieldView(auth),
                      ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterventionsHeroHeader extends StatelessWidget {
  const _InterventionsHeroHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 20),
      decoration: BoxDecoration(
        gradient: InterventionsUi.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: InterventionsUi.accent.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interventions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const EntityScopeAppBarAction(light: true),
        ],
      ),
    );
  }
}
