import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import 'rh_ui.dart';

class RhPresenceTab extends StatefulWidget {
  const RhPresenceTab({super.key, this.collaborateurId});

  final String? collaborateurId;

  @override
  State<RhPresenceTab> createState() => _RhPresenceTabState();
}

class _RhPresenceTabState extends State<RhPresenceTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final collabId = widget.collaborateurId ??
          (auth.isPrivilegedStaff ? null : auth.collaborateurId);
      final rows = await auth.api.listPresence(collaborateurId: collabId);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  ({int present, int retard, int absence}) get _stats {
    var present = 0;
    var retard = 0;
    var absence = 0;
    for (final r in _rows) {
      if (r['absence'] == true) {
        absence++;
      } else if (r['retard'] == true) {
        retard++;
      } else {
        present++;
      }
    }
    return (present: present, retard: retard, absence: absence);
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return const RhEmptyState(
        title: 'Aucune donnée de présence',
        subtitle: 'Les pointages apparaîtront ici.',
        icon: Icons.fingerprint_outlined,
      );
    }

    final stats = _stats;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              RhStatPill(
                label: 'Présent',
                value: '${stats.present}',
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              RhStatPill(
                label: 'Retard',
                value: '${stats.retard}',
                color: stats.retard > 0
                    ? const Color(0xFFB45309)
                    : AromaColors.zinc500,
              ),
              const SizedBox(width: 8),
              RhStatPill(
                label: 'Absence',
                value: '${stats.absence}',
                color: stats.absence > 0
                    ? const Color(0xFFDC2626)
                    : AromaColors.zinc500,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._rows.map((r) {
            final date = '${r['date'] ?? ''}';
            final absence = r['absence'] == true;
            final retard = r['retard'] == true;
            final style = RhUi.presenceStyle(
              absence: absence,
              retard: retard,
            );
            final label = absence
                ? 'Absence'
                : retard
                ? 'Retard'
                : 'Présent';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AromaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(style.icon, color: style.fg, size: 20),
                  ),
                  title: Text(
                    formatDateFr(date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: style.fg,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
