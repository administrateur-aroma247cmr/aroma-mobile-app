import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

class KpiChartCard extends StatelessWidget {
  const KpiChartCard({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc900,
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
            child,
          ],
        ),
      ),
    );
  }
}

class KpiEmptyChart extends StatelessWidget {
  const KpiEmptyChart({super.key, this.message = 'Aucune donnée'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
      ),
    );
  }
}

class KpiAlertBanner extends StatelessWidget {
  const KpiAlertBanner({
    super.key,
    required this.message,
    required this.icon,
    this.color = const Color(0xFFFFF1F2),
    this.borderColor = const Color(0xFFFECDD3),
    this.textColor = const Color(0xFF9F1239),
    this.iconColor = const Color(0xFFE11D48),
    this.badge,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: textColor, height: 1.35),
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
        ],
      ),
    );
  }
}
