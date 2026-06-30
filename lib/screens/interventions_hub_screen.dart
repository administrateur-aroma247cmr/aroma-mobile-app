import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
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

  static const _technicianTabIds = {'interventions', 'calendrier', 'reparations'};

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
      backgroundColor: AromaColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded)
              _InterventionsHeader(
                subtitle: technicianView
                    ? 'Interventions terrain · $moisLabel'
                    : 'Interventions · $moisLabel',
              ),
            if (!widget.embedded) const SizedBox(height: 8),
            InterventionsTabPills(
              tabs: tabs,
              selected: selectedTab,
              onSelected: _selectTab,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (selectedTab) {
                'calendrier' => InterventionsCalendarTab(
                    key: ValueKey(
                      'calendrier-${auth.currentEntityCode}-$technicianView',
                    ),
                    technicianFieldView: technicianView,
                  ),
                'adc' => InterventionsAdcTab(
                    key: ValueKey('adc-${auth.currentEntityCode}'),
                  ),
                'transport' => InterventionsTransportTab(
                    key: ValueKey('transport-${auth.currentEntityCode}'),
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
                      'interventions-${auth.currentEntityCode}-$technicianView',
                    ),
                    technicianFieldView: technicianView,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InterventionsHeader extends StatelessWidget {
  const _InterventionsHeader({required this.subtitle});

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
              gradient: InterventionsUi.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
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
                  'Mes interventions',
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
