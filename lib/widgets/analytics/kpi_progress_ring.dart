import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';
import 'kpi_format.dart';

class KpiProgressRing extends StatelessWidget {
  const KpiProgressRing({
    super.key,
    required this.value,
    this.label,
    this.color = const Color(0xFF7C3AED),
    this.size = 120,
  });

  final double value;
  final String? label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: v / 100,
                strokeWidth: 10,
                backgroundColor: AromaColors.zinc100,
                color: color,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatPct(v),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AromaColors.zinc900,
                      ),
                    ),
                    if (label != null)
                      Text(
                        label!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AromaColors.zinc500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KpiProgressRingCard extends StatelessWidget {
  const KpiProgressRingCard({
    super.key,
    required this.title,
    required this.pct,
    this.description,
    this.sublabel,
    this.color = const Color(0xFF7C3AED),
  });

  final String title;
  final String? description;
  final double pct;
  final String? sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AromaColors.zinc200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
              ),
            ],
            const SizedBox(height: 16),
            KpiProgressRing(value: pct, label: sublabel, color: color),
          ],
        ),
      ),
    );
  }
}
