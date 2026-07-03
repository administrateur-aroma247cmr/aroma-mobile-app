import 'package:flutter/material.dart';

import '../../models/tache.dart';
import '../../utils/task_rules.dart';
import '../../theme/aroma_theme.dart';

/// Palette module Tâches — alignée sur le dégradé violet/indigo du CRM web.
abstract final class TaskUi {
  static const gradientStart = Color(0xFF8B5CF6);
  static const gradientEnd = Color(0xFF4F46E5);
  static const accent = Color(0xFF6366F1);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static Color priorityColor(String? priorite) => switch (priorite) {
        'Haute' => const Color(0xFFDC2626),
        'Basse' => const Color(0xFF2563EB),
        _ => const Color(0xFFEA580C),
      };

  static bool isOverdue(Tache t) {
    if (t.isTerminee || isTaskClosed(t)) return false;
    final raw = t.dateButoire;
    if (raw == null || raw.isEmpty) return false;
    final parsed = DateTime.tryParse(
      raw.length >= 10 ? raw : '$raw-01',
    );
    if (parsed == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(parsed.year, parsed.month, parsed.day);
    return due.isBefore(today);
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class TaskMetaChip extends StatelessWidget {
  const TaskMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.tint,
  });

  final IconData icon;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AromaColors.zinc500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: TaskUi.gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AromaColors.zinc500),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
