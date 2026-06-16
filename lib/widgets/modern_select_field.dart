import 'package:flutter/material.dart';

import '../theme/aroma_theme.dart';
import 'modern_bottom_sheet.dart';

const _clearSentinel = Object();

class ModernSelectOption<T> {
  const ModernSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Champ sélection moderne — ouvre une bottom sheet searchable.
class ModernSelectField<T> extends StatelessWidget {
  const ModernSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon = Icons.expand_more_rounded,
    this.leadingIcon,
    this.allowClear = true,
    this.clearLabel = 'Aucun',
  });

  final String label;
  final String hint;
  final List<ModernSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final IconData icon;
  final IconData? leadingIcon;
  final bool allowClear;
  final String clearLabel;

  String? get _displayLabel {
    if (value == null) return null;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModernBottomSheet<Object?>(
      context: context,
      builder: (_) => _ModernSelectSheet<T>(
        title: label,
        options: options,
        selected: value,
        allowClear: allowClear,
        clearLabel: clearLabel,
      ),
    );
    if (!context.mounted || picked == null) return;
    if (picked == _clearSentinel) {
      onChanged(null);
    } else {
      onChanged(picked as T);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayLabel;
    final hasValue = display != null && display.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AromaColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasValue
                      ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                      : const Color(0xFFE4E4E7),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        size: 20,
                        color: hasValue
                            ? const Color(0xFF6366F1)
                            : AromaColors.zinc500,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        hasValue ? display : hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              hasValue ? FontWeight.w500 : FontWeight.w400,
                          color: hasValue
                              ? AromaColors.zinc900
                              : AromaColors.zinc500,
                        ),
                      ),
                    ),
                    Icon(icon, color: AromaColors.zinc500, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModernMultiSelectField<T> extends StatelessWidget {
  const ModernMultiSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.values,
    required this.onChanged,
    this.leadingIcon,
  });

  final String label;
  final String hint;
  final List<ModernSelectOption<T>> options;
  final Set<T> values;
  final ValueChanged<Set<T>> onChanged;
  final IconData? leadingIcon;

  Future<void> _open(BuildContext context) async {
    final picked = await showModernBottomSheet<Set<T>?>(
      context: context,
      builder: (_) => _ModernMultiSelectSheet<T>(
        title: label,
        options: options,
        selected: Set<T>.from(values),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final labels = options
        .where((o) => values.contains(o.value))
        .map((o) => o.label)
        .toList();
    final summary = labels.isEmpty
        ? hint
        : labels.length <= 2
        ? labels.join(', ')
        : '${labels.length} sélectionné(s)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc800,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AromaColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 20, color: AromaColors.zinc500),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: labels.isEmpty
                          ? Text(
                              summary,
                              style: const TextStyle(color: AromaColors.zinc500),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: labels
                                  .map(
                                    (l) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AromaColors.zinc500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernSelectSheet<T> extends StatefulWidget {
  const _ModernSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.allowClear,
    required this.clearLabel,
  });

  final String title;
  final List<ModernSelectOption<T>> options;
  final T? selected;
  final bool allowClear;
  final String clearLabel;

  @override
  State<_ModernSelectSheet<T>> createState() => _ModernSelectSheetState<T>();
}

class _ModernSelectSheetState<T> extends State<_ModernSelectSheet<T>> {
  String _query = '';

  List<ModernSelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where(
          (o) =>
              o.label.toLowerCase().contains(q) ||
              (o.subtitle ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ModernBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(12, 48, 12, 12),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              modernSheetDragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AromaColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                  children: [
                    if (widget.allowClear)
                      _OptionTile(
                        label: widget.clearLabel,
                        icon: Icons.clear_rounded,
                        selected: widget.selected == null,
                        onTap: () => Navigator.pop(context, _clearSentinel),
                      ),
                    ..._filtered.map(
                      (o) => _OptionTile(
                        label: o.label,
                        subtitle: o.subtitle,
                        icon: o.icon,
                        selected: o.value == widget.selected,
                        onTap: () => Navigator.pop(context, o.value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModernMultiSelectSheet<T> extends StatefulWidget {
  const _ModernMultiSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<ModernSelectOption<T>> options;
  final Set<T> selected;

  @override
  State<_ModernMultiSelectSheet<T>> createState() =>
      _ModernMultiSelectSheetState<T>();
}

class _ModernMultiSelectSheetState<T> extends State<_ModernMultiSelectSheet<T>> {
  late Set<T> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.selected);
  }

  List<ModernSelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ModernBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(12, 48, 12, 12),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              modernSheetDragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text('Valider (${_selected.length})'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AromaColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final o = _filtered[i];
                    final checked = _selected.contains(o.value);
                    return _OptionTile(
                      label: o.label,
                      subtitle: o.subtitle,
                      icon: o.icon,
                      selected: checked,
                      multi: true,
                      onTap: () {
                        setState(() {
                          if (checked) {
                            _selected.remove(o.value);
                          } else {
                            _selected.add(o.value);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.multi = false,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
            : AromaColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                    : const Color(0xFFE4E4E7),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? const Color(0xFF6366F1)
                          : AromaColors.zinc500,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AromaColors.zinc500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    multi
                        ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                        : (selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded),
                    color: selected
                        ? const Color(0xFF6366F1)
                        : AromaColors.zinc500,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
