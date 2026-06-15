import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/analytics.dart';
import '../../theme/aroma_theme.dart';
import 'kpi_format.dart';

class KpiAreaChart extends StatelessWidget {
  const KpiAreaChart({
    super.key,
    required this.data,
    this.color = const Color(0xFF7C3AED),
    this.height = 200,
    this.valueFormatter,
  });

  final List<KpiTrendPoint> data;
  final Color color;
  final double height;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final fmt = valueFormatter ?? (v) => formatKpiNumber(v, compact: true);
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].value),
    ];
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => Text(
                  formatKpiAxisTick(v),
                  style: const TextStyle(fontSize: 10, color: AromaColors.zinc500),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final m = data[i].mois;
                  final short = m.length >= 7 ? m.substring(5) : m;
                  return Text(
                    short,
                    style: const TextStyle(fontSize: 10, color: AromaColors.zinc500),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.round();
                final label = i >= 0 && i < data.length ? data[i].mois : '';
                return LineTooltipItem(
                  '$label\n${fmt(s.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
