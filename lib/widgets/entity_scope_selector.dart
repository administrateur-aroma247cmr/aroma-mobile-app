import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/entity_flags.dart';
import '../utils/entity_scope.dart';
import 'modern_bottom_sheet.dart';

/// Sélecteur CM / CI / Tous les pays (aligné CRM web).
class EntityScopeSelector extends StatefulWidget {
  const EntityScopeSelector({super.key, this.compact = false});

  final bool compact;

  @override
  State<EntityScopeSelector> createState() => _EntityScopeSelectorState();
}

class _EntityScopeSelectorState extends State<EntityScopeSelector> {
  Map<String, String> _labels = const {};
  bool _loadingLabels = false;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final auth = context.read<AuthProvider>();
    if (!auth.showEntitySelector) return;
    setState(() => _loadingLabels = true);
    try {
      final rows = await auth.api.listBusinessEntities();
      if (!mounted) return;
      setState(() {
        _labels = {for (final r in rows) r.code: r.label};
        _loadingLabels = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLabels = false);
    }
  }

  String _label(String code) =>
      entityDisplayLabel(code, labels: _labels);

  Future<void> _pickEntity(AuthProvider auth) async {
    final options = <String>[
      if (canShowEntityScopeAll(
        auth.entityCodes,
        canEntityScopeAllFlag: auth.canEntityScopeAll,
      ))
        entityScopeAll,
      ...auth.entityCodes,
    ];
    if (options.length <= 1) return;

    final picked = await showModernListSheet<String>(
      context: context,
      title: 'Pays actifs',
      theme: ModernSheetThemes.neutral,
      children: options.map((code) {
        final selected = auth.currentEntityCode == code;
        final flag = isEntityScopeAll(code) ? null : entityFlagEmoji(code);
        return ModernSheetListTile(
          title: _label(code),
          leading: flag != null
              ? Text(flag, style: const TextStyle(fontSize: 22))
              : const Icon(Icons.public),
          selected: selected,
          onTap: () => Navigator.pop(context, code),
        );
      }).toList(),
    );

    if (picked != null && mounted) {
      await auth.setEntityCode(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.showEntitySelector) return const SizedBox.shrink();

    final code = auth.currentEntityCode ?? auth.entityCodes.first;
    final flag = isEntityScopeAll(code) ? null : entityFlagEmoji(code);
    final label = _label(code);

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: flag != null
              ? Text(flag, style: const TextStyle(fontSize: 16))
              : Icon(
                  Icons.public,
                  size: 18,
                  color: AromaColors.zinc800,
                ),
          label: Text(
            isEntityScopeAll(code) ? 'Tous' : code,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: _loadingLabels ? null : () => _pickEntity(auth),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PAYS ACTIFS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AromaColors.zinc500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AromaColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _loadingLabels ? null : () => _pickEntity(auth),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (flag != null)
                      Text(flag, style: const TextStyle(fontSize: 20))
                    else
                      Icon(Icons.public, color: AromaColors.zinc500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AromaColors.zinc500),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip compact pour la barre d'app (modules poussés).
class EntityScopeAppBarAction extends StatelessWidget {
  const EntityScopeAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const EntityScopeSelector(compact: true);
  }
}

/// Recharge [onEntityChanged] quand l'entité active change.
mixin EntityScopeReloadMixin<T extends StatefulWidget> on State<T> {
  String? _entityWatch;

  void watchEntityScope(VoidCallback onEntityChanged) {
    final code = context.watch<AuthProvider>().currentEntityCode;
    if (_entityWatch != code) {
      _entityWatch = code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onEntityChanged();
      });
    }
  }
}
