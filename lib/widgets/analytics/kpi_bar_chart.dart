import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/analytics.dart';
import '../../theme/aroma_theme.dart';
import 'kpi_format.dart';

enum KpiBarLayout { vertical, horizontal }

class KpiBarChart extends StatelessWidget {
  const KpiBarChart({
    super.key,
    required this.data,
    this.layout = KpiBarLayout.horizontal,
    this.color = const Color(0xFF7C3AED),
    this.maxItems = 8,
    this.valueFormatter,
    this.height,
  });

  final List<KpiSeriesPoint> data;
  final KpiBarLayout layout;
  final Color color;
  final int maxItems;
  final String Function(double)? valueFormatter;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (layout == KpiBarLayout.horizontal) {
      return KpiHorizontalBarChart(
        data: data,
        color: color,
        maxItems: maxItems,
        valueFormatter: valueFormatter,
      );
    }
    return _VerticalBarChart(
      data: data,
      color: color,
      maxItems: maxItems,
      valueFormatter: valueFormatter,
      height: height,
    );
  }
}

class _VerticalBarChart extends StatelessWidget {
  const _VerticalBarChart({
    required this.data,
    required this.color,
    required this.maxItems,
    this.valueFormatter,
    this.height,
  });

  final List<KpiSeriesPoint> data;
  final Color color;
  final int maxItems;
  final String Function(double)? valueFormatter;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final items = data.where((e) => e.value > 0).take(maxItems).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final fmt = valueFormatter ?? (v) => formatKpiNumber(v, compact: true);
    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height ?? 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal <= 0 ? 1 : maxVal * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${items[group.x.toInt()].label}\n${fmt(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
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
                reservedSize: 36,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final label = items[i].label;
                  final short =
                      label.length > 8 ? '${label.substring(0, 7)}…' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].value,
                    color: color,
                    width: 20,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class KpiHorizontalBarChart extends StatelessWidget {
  const KpiHorizontalBarChart({
    super.key,
    required this.data,
    this.color = const Color(0xFF7C3AED),
    this.maxItems = 8,
    this.valueFormatter,
  });

  final List<KpiSeriesPoint> data;
  final Color color;
  final int maxItems;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final items = data.where((e) => e.value > 0).take(maxItems).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final fmt = valueFormatter ?? (v) => formatKpiNumber(v, compact: true);

    return Column(
      children: [
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AromaColors.zinc800,
                        ),
                      ),
                    ),
                    Text(
                      fmt(e.value),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxVal > 0 ? (e.value / maxVal).clamp(0.0, 1.0) : 0,
                    minHeight: 10,
                    backgroundColor: AromaColors.zinc100,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
