import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_technician_actions.dart';
import '../widgets/interventions/interventions_ui.dart';

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
    if (i == null || action != TechnicianInterventionAction.demarrer) return;

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

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InterventionsUi.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prise en charge',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AromaColors.zinc500,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _actionBusy
                ? null
                : () => _onTechnicianAction(TechnicianInterventionAction.demarrer),
            style: InterventionsUi.technicianActionStyle(isReportAction: false),
            child: _actionBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Démarrer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
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
    final showAction = widget.technicianFieldView &&
        technicianInterventionAction(i.etat) ==
            TechnicianInterventionAction.demarrer;

    return RefreshIndicator(
      color: InterventionsUi.accent,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _HeroCard(intervention: i),
          if (showAction) ...[
            const SizedBox(height: 14),
            _buildActionButton(),
          ],
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Client & site',
            icon: Icons.business_outlined,
            rows: [
              _InfoRow('Client', i.clientNom ?? '—'),
              _InfoRow('Site', i.siteAffiche.isEmpty ? '—' : i.siteAffiche),
              _InfoRow('Ville', i.ville ?? '—'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Intervention',
            icon: Icons.build_outlined,
            rows: [
              if ((i.ref ?? '').isNotEmpty) _InfoRow('Référence', i.ref!),
              _InfoRow('Type', i.typeIntervention ?? '—'),
              _InfoRow('Date', formatDateFr(i.dateIntervention)),
              _InfoRow(
                'État',
                i.etat ?? '—',
                valueWidget: InterventionEtatBadge(etat: i.etat),
              ),
              _InfoRow('Technicien', i.technicienNom ?? '—'),
              _InfoRow('Auteur', i.auteur ?? '—'),
            ],
          ),
          if ((i.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
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
  const _HeroCard({required this.intervention});

  final Intervention intervention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: InterventionsUi.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: InterventionsUi.accent.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intervention.titreAffiche,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      intervention.clientNom ?? '—',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InterventionEtatBadge(etat: intervention.etat),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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
      padding: const EdgeInsets.all(18),
      decoration: InterventionsUi.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: InterventionsUi.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AromaColors.zinc900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
          fontSize: 14,
          height: 1.45,
          color: AromaColors.zinc800,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AromaColors.zinc900,
                  height: 1.35,
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
