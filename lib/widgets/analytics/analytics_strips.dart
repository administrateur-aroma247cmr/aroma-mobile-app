import 'package:flutter/material.dart';

import '../../models/analytics.dart';
import '../../theme/aroma_theme.dart';
import 'kpi_format.dart';
import 'kpi_metric_card.dart';

class AnalyticsParcStrip extends StatelessWidget {
  const AnalyticsParcStrip({super.key, required this.data});

  final AnalyticsParcKpi data;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.people_outline, 'Clients actifs', formatKpiNumber(data.clientsActifs)),
      (Icons.business_outlined, 'Sites', formatKpiNumber(data.nbSites)),
      (Icons.air_outlined, 'Diffuseurs', formatKpiNumber(data.nbDiffuseurs)),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AromaColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AromaColors.zinc200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(items[i].$1, size: 14, color: const Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AromaColors.zinc500,
                          ),
                        ),
                        Text(
                          items[i].$3,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AromaColors.zinc900,
                            height: 1.1,
                          ),
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

class AnalyticsRelationStrip extends StatelessWidget {
  const AnalyticsRelationStrip({super.key, required this.data});

  final AnalyticsRelationClientKpi data;

  @override
  Widget build(BuildContext context) {
    return KpiMetricGrid(
      children: [
        KpiMetricCard(
          label: 'Clients < 3 interactions',
          value: formatKpiNumber(data.clientsInteractionsFaibles),
          sublabel: 'Alerte relation (mois en cours)',
          icon: Icons.people_alt_outlined,
          accent: KpiAccent.rose,
        ),
        KpiMetricCard(
          label: 'Rapports CDC envoyés',
          value: formatKpiNumber(data.rapportsEnvoyes),
          sublabel: '${data.rapportsManquants} manquant(s)',
          icon: Icons.description_outlined,
          accent: KpiAccent.violet,
        ),
        KpiMetricCard(
          label: 'Taux rapports',
          value: formatPct(data.tauxRapportPct),
          sublabel: 'Couverture clients',
          icon: Icons.assignment_turned_in_outlined,
          accent: KpiAccent.cyan,
        ),
      ],
    );
  }
}
