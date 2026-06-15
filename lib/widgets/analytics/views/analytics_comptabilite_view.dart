import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_area_chart.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';
import '../kpi_progress_ring.dart';

class AnalyticsComptabiliteView extends StatelessWidget {
  const AnalyticsComptabiliteView({super.key, required this.data});

  final AnalyticsComptabiliteKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'CA crédits',
              value: formatFcfa(data.caCredits),
              sublabel: 'Recettes client (période)',
              icon: Icons.trending_up,
              accent: KpiAccent.emerald,
              highlight: true,
            ),
            KpiMetricCard(
              label: 'Charges débit',
              value: formatFcfa(data.chargesDebits),
              icon: Icons.balance_outlined,
              accent: KpiAccent.slate,
            ),
            KpiMetricCard(
              label: 'Marge',
              value: formatPct(data.margePct),
              sublabel: 'CA − charges',
              icon: Icons.calculate_outlined,
              accent: KpiAccent.emerald,
            ),
            if (data.montantContratTtc != null)
              KpiMetricCard(
                label: 'Contrat client',
                value: formatFcfa(data.montantContratTtc!),
                icon: Icons.description_outlined,
                accent: KpiAccent.emerald,
              ),
            KpiMetricCard(
              label: 'Transport terrain',
              value: formatFcfa(data.transportTotal),
              icon: Icons.local_shipping_outlined,
              accent: KpiAccent.cyan,
            ),
            if (data.demandesMontant != null)
              KpiMetricCard(
                label: 'Demandes à payer',
                value: formatFcfa(data.demandesMontant!),
                sublabel: data.demandesNonPayees != null
                    ? '${formatKpiNumber(data.demandesNonPayees!)} non payées'
                    : null,
                icon: Icons.account_balance_wallet_outlined,
                accent: KpiAccent.slate,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.parSite.isNotEmpty)
          KpiChartCard(
            title: 'CA par site',
            description: 'Transactions comptables — crédits',
            child: KpiBarChart(
              data: data.parSite,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF10B981),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Écritures validées',
          pct: data.ecrituresValideesPct,
          sublabel: 'validées',
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 12),
        if (data.depensesMensuelles.isNotEmpty)
          KpiChartCard(
            title: 'Dépenses mensuelles',
            child: KpiAreaChart(
              data: data.depensesMensuelles,
              color: const Color(0xFFEF4444),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.resultatMensuel.isNotEmpty)
          KpiChartCard(
            title: 'Résultat mensuel',
            child: KpiAreaChart(
              data: data.resultatMensuel,
              color: const Color(0xFF6366F1),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.tendanceCa.isNotEmpty)
          KpiChartCard(
            title: 'Tendance CA',
            child: KpiAreaChart(
              data: data.tendanceCa,
              color: const Color(0xFF10B981),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parCompte.isNotEmpty)
          KpiChartCard(
            title: 'Par compte',
            child: KpiBarChart(
              data: data.parCompte,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF64748B),
            ),
          ),
        if (data.demandesParStatut.isNotEmpty) ...[
          const SizedBox(height: 12),
          KpiChartCard(
            title: 'Demandes par statut',
            child: KpiBarChart(data: data.demandesParStatut),
          ),
        ],
      ],
    );
  }
}
