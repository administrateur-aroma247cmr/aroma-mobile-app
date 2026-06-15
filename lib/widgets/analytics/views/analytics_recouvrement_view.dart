import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_donut_chart.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';

class AnalyticsRecouvrementView extends StatelessWidget {
  const AnalyticsRecouvrementView({super.key, required this.data});

  final AnalyticsRecouvrementKpi data;

  @override
  Widget build(BuildContext context) {
    final hasRetard = data.montantRetard > 0 || data.nbFacturesRetard > 0;
    final trancheData = data.montantParTrancheRetard.isNotEmpty
        ? data.montantParTrancheRetard
        : data.parTrancheRetard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasRetard)
          KpiAlertBanner(
            icon: Icons.warning_amber_rounded,
            message:
                '${formatFcfa(data.montantRetard)} en retard (${formatKpiNumber(data.nbFacturesRetard)} facture${data.nbFacturesRetard > 1 ? 's' : ''})${data.joursRetardMax > 0 ? ' — jusqu\'à ${data.joursRetardMax.toStringAsFixed(0)} j' : ''}.',
          ),
        if (hasRetard) const SizedBox(height: 12),
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'Montant en retard',
              value: formatFcfa(data.montantRetard),
              sublabel: '${formatKpiNumber(data.nbFacturesRetard)} facture(s)',
              icon: Icons.warning_amber_rounded,
              accent: KpiAccent.rose,
              highlight: hasRetard,
            ),
            KpiMetricCard(
              label: 'Montant attendu (mois)',
              value: formatFcfa(data.montantAttendu),
              sublabel:
                  '${formatKpiNumber(data.nbFacturesAttendu)} échéance(s) ce mois',
              icon: Icons.calendar_month_outlined,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'Encours recouvrable',
              value: formatFcfa(data.montantEncours),
              sublabel: 'Total impayé',
              icon: Icons.account_balance_wallet_outlined,
              accent: KpiAccent.slate,
            ),
            KpiMetricCard(
              label: 'Retard moyen',
              value: data.joursRetardMoyen > 0
                  ? '${data.joursRetardMoyen.toStringAsFixed(0)} j'
                  : '—',
              sublabel: data.joursRetardMax > 0
                  ? 'Max ${data.joursRetardMax.toStringAsFixed(0)} j'
                  : 'Aucune facture en retard',
              icon: Icons.balance_outlined,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'Relances totales',
              value: formatKpiNumber(data.nbRelancesTotal),
              sublabel:
                  '${formatKpiNumber(data.facturesAvecRelance)} facture(s) relancée(s)',
              icon: Icons.notifications_active_outlined,
              accent: KpiAccent.violet,
            ),
            KpiMetricCard(
              label: 'Sans assignation',
              value: formatKpiNumber(data.facturesSansAssignation),
              icon: Icons.person_off_outlined,
              accent: KpiAccent.slate,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (trancheData.isNotEmpty)
          KpiChartCard(
            title: 'Retard par ancienneté',
            child: Column(
              children: [
                KpiDonutChart(data: trancheData, centerLabel: 'FCFA'),
                const SizedBox(height: 16),
                KpiBarChart(
                  data: trancheData,
                  valueFormatter: (v) => formatFcfa(v),
                  color: const Color(0xFFE11D48),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (data.montantParAssigne.isNotEmpty)
          KpiChartCard(
            title: 'Montant par assigné',
            child: KpiBarChart(
              data: data.montantParAssigne,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF7C3AED),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parNombreRelances.isNotEmpty)
          KpiChartCard(
            title: 'Par nombre de relances',
            child: KpiBarChart(data: data.parNombreRelances),
          ),
        const SizedBox(height: 12),
        if (data.topFacturesRetard.isNotEmpty)
          KpiChartCard(
            title: 'Top factures en retard',
            child: KpiBarChart(
              data: data.topFacturesRetard,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFE11D48),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
      ],
    );
  }
}
