import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../theme/aroma_theme.dart';

class KpiBarChartCard extends StatelessWidget {
  const KpiBarChartCard({
    super.key,
    required this.title,
    required this.data,
    this.maxItems = 6,
  });

  final String title;
  final List<KpiSeriesPoint> data;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final items = data.where((e) => e.value > 0).take(maxItems).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...items.map((e) {
              final frac = maxVal > 0 ? e.value / maxVal : 0.0;
              return Padding(
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
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _fmtNum(e.value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AromaColors.zinc100,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class KpiPieChartCard extends StatelessWidget {
  const KpiPieChartCard({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final List<KpiSeriesPoint> data;

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final items = data.where((e) => e.value > 0).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].value,
                        title: '',
                        color: _colors[i % _colors.length],
                        radius: 52,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < items.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${items[i].label} (${_fmtNum(items[i].value)})',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KpiLineChartCard extends StatelessWidget {
  const KpiLineChartCard({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final List<KpiTrendPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 1 : maxY * 1.15,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                          return Text(short, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF7C3AED),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KpiProgressRingCard extends StatelessWidget {
  const KpiProgressRingCard({
    super.key,
    required this.title,
    required this.pct,
    this.sublabel,
  });

  final String title;
  final double pct;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final v = pct.clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v / 100,
                    strokeWidth: 8,
                    backgroundColor: AromaColors.zinc100,
                    color: const Color(0xFF7C3AED),
                  ),
                  Center(
                    child: Text(
                      '${v.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sublabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtNum(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toStringAsFixed(1);
}
