import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

/// Palette module Caisse — alignée sur le dégradé orange du CRM web.
abstract final class CaisseUi {
  static const gradientStart = Color(0xFFF97316);
  static const gradientEnd = Color(0xFFD97706);
  static const accent = Color(0xFFEA580C);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}

class CaisseTabConfig {
  const CaisseTabConfig(this.id, this.label, this.icon, {this.count});

  final String id;
  final String label;
  final IconData icon;
  final int? count;
}

class CaisseTabPills extends StatefulWidget {
  const CaisseTabPills({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<CaisseTabConfig> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<CaisseTabPills> createState() => _CaisseTabPillsState();
}

class _CaisseTabPillsState extends State<CaisseTabPills> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(CaisseTabPills oldWidget) {
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
      child: Stack(
        children: [
          ListView.separated(
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
                        gradient: isSelected ? CaisseUi.gradient : null,
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
                                  color: CaisseUi.accent.withValues(alpha: 0.25),
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
                            color: isSelected
                                ? Colors.white
                                : AromaColors.zinc500,
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
                          if (tab.count != null && tab.count! > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : CaisseUi.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${tab.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : CaisseUi.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AromaColors.canvas.withValues(alpha: 0),
                      AromaColors.canvas,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
