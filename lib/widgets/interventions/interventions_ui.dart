import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

/// Palette module Interventions — bleu terrain (aligné CRM web).
abstract final class InterventionsUi {
  static const gradientStart = Color(0xFF0284C7);
  static const gradientEnd = Color(0xFF0EA5E9);
  static const accent = Color(0xFF38BDF8);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}

class InterventionsTabConfig {
  const InterventionsTabConfig(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class InterventionsTabPills extends StatefulWidget {
  const InterventionsTabPills({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<InterventionsTabConfig> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<InterventionsTabPills> createState() => _InterventionsTabPillsState();
}

class _InterventionsTabPillsState extends State<InterventionsTabPills> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(InterventionsTabPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureKeys();
    if (oldWidget.selected != widget.selected ||
        oldWidget.tabs.length != widget.tabs.length) {
      _scrollToSelected();
    }
  }

  void _ensureKeys() {
    for (final tab in widget.tabs) {
      _keys.putIfAbsent(tab.id, GlobalKey.new);
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _keys[widget.selected];
      final ctx = key?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tab = widget.tabs[i];
          final isSelected = widget.selected == tab.id;
          return KeyedSubtree(
            key: _keys[tab.id],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSelected(tab.id),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? InterventionsUi.gradient : null,
                    color: isSelected ? null : AromaColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFFE4E4E7),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: InterventionsUi.accent
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color:
                            isSelected ? Colors.white : AromaColors.zinc500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AromaColors.zinc800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InterventionsSectionHeader extends StatelessWidget {
  const InterventionsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AromaColors.zinc900,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
          ),
        ],
      ],
    );
  }
}

class InterventionsEmptyState extends StatelessWidget {
  const InterventionsEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.build_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

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
                gradient: InterventionsUi.gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
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
          ],
        ),
      ),
    );
  }
}

class InterventionsListCard extends StatelessWidget {
  const InterventionsListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.icon = Icons.chevron_right_rounded,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AromaColors.zinc800,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(icon, color: AromaColors.zinc500, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InterventionsDetailRow extends StatelessWidget {
  const InterventionsDetailRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AromaColors.zinc500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AromaColors.zinc900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showInterventionsDetailSheet({
  required BuildContext context,
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AromaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AromaColors.zinc200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

Widget interventionsErrorState({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
