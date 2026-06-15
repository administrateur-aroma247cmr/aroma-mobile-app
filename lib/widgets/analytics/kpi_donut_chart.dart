import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/analytics.dart';
import '../../theme/aroma_theme.dart';
import 'kpi_format.dart';

class KpiDonutChart extends StatelessWidget {
  const KpiDonutChart({
    super.key,
    required this.data,
    this.centerLabel,
    this.size = 140,
  });

  final List<KpiSeriesPoint> data;
  final String? centerLabel;
  final double size;

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final items = data.where((e) => e.value > 0).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold<double>(0, (s, e) => s + e.value);
    final chartRadius = size * 0.30;
    final centerRadius = size * 0.20;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: Center(
            child: SizedBox(
              height: size,
              width: size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: centerRadius,
                      sections: [
                        for (var i = 0; i < items.length; i++)
                          PieChartSectionData(
                            value: items[i].value,
                            title: '',
                            color: _colors[i % _colors.length],
                            radius: chartRadius,
                          ),
                      ],
                    ),
                  ),
                  if (centerLabel != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatKpiNumber(total, compact: true),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AromaColors.zinc900,
                          ),
                        ),
                        Text(
                          centerLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AromaColors.zinc500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < items.length; i++)
              _LegendItem(
                color: _colors[i % _colors.length],
                label: items[i].label,
                value: formatKpiNumber(items[i].value),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label ($value)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AromaColors.zinc500),
            ),
          ),
        ],
      ),
    );
  }
}
