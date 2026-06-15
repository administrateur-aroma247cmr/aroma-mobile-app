import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import 'rh_ui.dart';

class RhDocumentsTab extends StatefulWidget {
  const RhDocumentsTab({super.key, this.collaborateurId});

  final String? collaborateurId;

  @override
  State<RhDocumentsTab> createState() => _RhDocumentsTabState();
}

class _RhDocumentsTabState extends State<RhDocumentsTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final collabId = widget.collaborateurId ??
        context.read<AuthProvider>().collaborateurId;
    if (collabId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final docs = await context.read<AuthProvider>().api.listDocumentRh(
        collabId,
      );
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_docs.isEmpty) {
      return const RhEmptyState(
        title: 'Aucun document RH',
        subtitle: 'Vos documents administratifs apparaîtront ici.',
        icon: Icons.folder_open_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = _docs[i];
          final title =
              '${d['type_document'] ?? d['nom_fichier'] ?? 'Document'}';
          final date = formatDateFr('${d['date_upload'] ?? ''}');

          return Container(
            decoration: BoxDecoration(
              color: AromaColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RhUi.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: RhUi.accent,
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(date),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AromaColors.zinc500,
              ),
            ),
          );
        },
      ),
    );
  }
}
