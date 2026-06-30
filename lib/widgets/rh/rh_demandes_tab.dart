import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/demande_rh.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/entity_scope_selector.dart';
import '../../widgets/modern_bottom_sheet.dart';
import 'rh_create_demande_sheet.dart';
import 'rh_demande_card.dart';
import 'rh_ui.dart';

class RhDemandesTab extends StatefulWidget {
  const RhDemandesTab({
    super.key,
    this.collaborateurId,
    this.executiveAll = false,
  });

  final String? collaborateurId;
  final bool executiveAll;

  @override
  State<RhDemandesTab> createState() => _RhDemandesTabState();
}

class _RhDemandesTabState extends State<RhDemandesTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<DemandeRh> _demandes = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AuthProvider>().api.listDemandesRh();
      if (!mounted) return;
      var filtered = list;
      if (widget.collaborateurId != null && !widget.executiveAll) {
        filtered = list
            .where((d) => d.idCollaborateur == widget.collaborateurId)
            .toList();
      }
      setState(() {
        _demandes = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _pendingCount =>
      _demandes.where((d) => d.statut == 'en_attente').length;

  Future<void> _openCreateDialog() async {
    final auth = context.read<AuthProvider>();
    if (!auth.canCreateRhDemande) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Création de demande non autorisée pour ce compte.'),
        ),
      );
      return;
    }
    final collabId = auth.collaborateurId;
    if (collabId == null) return;

    final result = await showModernBottomSheet<bool>(
      context: context,
      builder: (_) => ModernBottomSheetShell(
        useDraggable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            modernSheetDragHandle(),
            RhCreateDemandeSheet(collaborateurId: collabId),
          ],
        ),
      ),
    );
    if (result == true) await _reload();
  }

  Future<void> _patchStatut(DemandeRh d, String statut) async {
    try {
      await context.read<AuthProvider>().api.patchDemandeRh(d.id, {
        'statut': statut,
      });
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.canCreateRhDemande;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RhEmptyState(title: _error!, icon: Icons.error_outline_rounded);
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _reload,
          child: _demandes.isEmpty
              ? ListView(
                  children: [
                    RhEmptyState(
                      title: 'Aucune demande RH',
                      subtitle: canCreate
                          ? 'Créez une demande de congé, absence ou avance.'
                          : null,
                      icon: Icons.inbox_outlined,
                      actionLabel: canCreate ? 'Nouvelle demande' : null,
                      onAction: canCreate ? _openCreateDialog : null,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: _demandes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = _demandes[i];
                    return RhDemandeCard(
                      demande: d,
                      canValidate: auth.canValidateRhDemande,
                      onApprove: () => _patchStatut(d, 'approuve'),
                      onReject: () => _patchStatut(d, 'rejete'),
                    );
                  },
                ),
        ),
        if (canCreate)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: RhUi.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: RhUi.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'fab-rh-demande',
                onPressed: _openCreateDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Nouvelle demande',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_pendingCount > 0 && !canCreate)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_pendingCount en attente de validation',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
