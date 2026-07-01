import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_technician_actions.dart';
import '../widgets/interventions/interventions_ui.dart';
import 'intervention_rapport_screen.dart';

class InterventionDetailScreen extends StatefulWidget {
  const InterventionDetailScreen({
    super.key,
    required this.interventionId,
    this.initialSummary,
    this.technicianFieldView = false,
  });

  final String interventionId;
  final Intervention? initialSummary;
  final bool technicianFieldView;

  @override
  State<InterventionDetailScreen> createState() =>
      _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> {
  bool _loading = true;
  bool _actionBusy = false;
  String? _error;
  Intervention? _intervention;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _intervention = widget.initialSummary;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final row = await api.getIntervention(widget.interventionId);
      if (!mounted) return;
      setState(() {
        _intervention = row;
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

  Future<void> _onTechnicianAction(TechnicianInterventionAction action) async {
    final i = _intervention;
    if (i == null || action == TechnicianInterventionAction.none) return;

    if (action == TechnicianInterventionAction.creerRapport) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InterventionRapportScreen(
            interventionId: i.id,
            interventionSummary: i,
          ),
        ),
      );
      if (!mounted) return;
      _changed = true;
      await _load();
      return;
    }

    setState(() => _actionBusy = true);
    try {
      final api = context.read<AuthProvider>().api;
      final updated = await api.updateIntervention(i.id, {'etat': 'Démarré'});
      if (!mounted) return;
      setState(() {
        _intervention = updated;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervention démarrée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: InterventionsUi.canvasSoft,
        appBar: AppBar(
          backgroundColor: InterventionsUi.canvasSoft,
          foregroundColor: AromaColors.zinc900,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Intervention'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _intervention == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _intervention == null) {
      return interventionsErrorState(message: _error!, onRetry: _load);
    }

    final i = _intervention!;
    final action = widget.technicianFieldView
        ? technicianInterventionAction(i.etat)
        : TechnicianInterventionAction.none;
    final displayEtat = widget.technicianFieldView
        ? interventionEtatForTechnicianDisplay(i.etat)
        : i.etat;

    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _HeroCard(
            intervention: i,
            technicianFieldView: widget.technicianFieldView,
            action: action,
            actionBusy: _actionBusy,
            onAction: _onTechnicianAction,
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Client & site',
            icon: Icons.business_outlined,
            rows: [
              _InfoRow('Client', i.clientNom ?? '—'),
              _InfoRow('Site', i.siteAffiche.isEmpty ? '—' : i.siteAffiche),
              _InfoRow('Ville', i.ville ?? '—'),
            ],
          ),
          const SizedBox(height: 10),
          _InfoSection(
            title: 'Intervention',
            icon: Icons.build_outlined,
            rows: [
              if ((i.ref ?? '').isNotEmpty) _InfoRow('Référence', i.ref!),
              _InfoRow('Type', i.typeIntervention ?? '—'),
              _InfoRow('Date', formatDateFr(i.dateIntervention)),
              _InfoRow(
                'État',
                displayEtat ?? '—',
                valueWidget: InterventionEtatBadge(etat: displayEtat),
              ),
              _InfoRow('Technicien', i.technicienNom ?? '—'),
              _InfoRow('Auteur', i.auteur ?? '—'),
            ],
          ),
          if ((i.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Description',
              icon: Icons.notes_outlined,
              rows: [
                _InfoRow('', i.description!.trim(), multiline: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.intervention,
    this.technicianFieldView = false,
    this.action = TechnicianInterventionAction.none,
    this.actionBusy = false,
    this.onAction,
  });

  final Intervention intervention;
  final bool technicianFieldView;
  final TechnicianInterventionAction action;
  final bool actionBusy;
  final ValueChanged<TechnicianInterventionAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final showAction =
        technicianFieldView && action != TechnicianInterventionAction.none;
    final isReport = action == TechnicianInterventionAction.creerRapport;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: InterventionsUi.headerGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: InterventionsUi.accent.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intervention.titreAffiche,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      intervention.clientNom ?? '—',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InterventionEtatBadge(
                etat: technicianFieldView
                    ? interventionEtatForTechnicianDisplay(intervention.etat)
                    : intervention.etat,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _HeroChip(
                icon: Icons.calendar_today_outlined,
                label: formatDateFr(intervention.dateIntervention),
              ),
              if ((intervention.typeIntervention ?? '').trim().isNotEmpty)
                _HeroChip(
                  icon: Icons.category_outlined,
                  label: intervention.typeIntervention!,
                ),
              if (intervention.siteAffiche.isNotEmpty)
                _HeroChip(
                  icon: Icons.place_outlined,
                  label: intervention.siteAffiche,
                ),
            ],
          ),
          if (showAction) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: actionBusy || onAction == null
                  ? null
                  : () => onAction!(action),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isReport ? Colors.white : const Color(0xFF18181B),
                foregroundColor:
                    isReport ? InterventionsUi.accent : Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: InterventionsUi.accent.withValues(
                  alpha: 0.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: actionBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isReport
                            ? InterventionsUi.accent
                            : Colors.white,
                      ),
                    )
                  : Text(technicianInterventionActionLabel(action)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: InterventionsUi.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: InterventionsUi.accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AromaColors.zinc900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: row,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
    this.label,
    this.value, {
    this.valueWidget,
    this.multiline = false,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty && multiline) {
      return Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AromaColors.zinc800,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AromaColors.zinc500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: valueWidget ??
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AromaColors.zinc900,
                  height: 1.3,
                ),
              ),
        ),
      ],
    );
  }
}

Future<bool?> openInterventionDetail(
  BuildContext context, {
  required Intervention intervention,
  bool technicianFieldView = false,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => InterventionDetailScreen(
        interventionId: intervention.id,
        initialSummary: intervention,
        technicianFieldView: technicianFieldView,
      ),
    ),
  );
}
