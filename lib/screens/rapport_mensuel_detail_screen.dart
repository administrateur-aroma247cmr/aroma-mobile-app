import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/interventions/interventions_ui.dart';

enum _RapportSection { interactions, planning }

class RapportMensuelDetailScreen extends StatefulWidget {
  const RapportMensuelDetailScreen({
    super.key,
    required this.clientId,
    required this.clientNom,
    required this.mois,
  });

  final String clientId;
  final String clientNom;
  final String mois;

  @override
  State<RapportMensuelDetailScreen> createState() =>
      _RapportMensuelDetailScreenState();
}

class _RapportMensuelDetailScreenState
    extends State<RapportMensuelDetailScreen> {
  bool _loading = true;
  String? _error;
  RapportMensuelDetail? _detail;
  _RapportSection _section = _RapportSection.interactions;

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
      final api = context.read<AuthProvider>().api;
      final detail = await api.getRapportMensuelDetail(
        clientId: widget.clientId,
        mois: widget.mois,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  List<String> _lieux(RapportMensuelDetail d) {
    final set = <String>{};
    for (final site in d.sites) {
      final v = site.trim();
      if (v.isNotEmpty) set.add(v);
    }
    for (final row in [
      ...d.interactionsAdc,
      ...d.interactionsVdc,
      ...d.interactionsRefill,
    ]) {
      final v = (row.lieu ?? '').trim();
      set.add(v.isEmpty ? '—' : v);
    }
    final lieux = set.toList()..sort((a, b) => a.compareTo(b));
    return lieux;
  }

  List<RapportMensuelLigne> _rowsForLieu(
    List<RapportMensuelLigne> rows,
    String lieu,
  ) {
    return rows
        .where((row) => _normalizeLieu(row.lieu) == _normalizeLieu(lieu))
        .toList();
  }

  String _normalizeLieu(String? lieu) {
    final v = (lieu ?? '').trim();
    return v.isEmpty ? '—' : v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: Text(widget.clientNom),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? interventionsErrorState(message: _error!, onRetry: _reload)
              : _detail == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '${_detail!.clientNom}${_detail!.codeClient != null ? ' · ${_detail!.codeClient}' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _detail!.moisLabel,
                            style: const TextStyle(color: AromaColors.zinc500),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InterventionsToggleKpiCard(
                                  title: 'Interactions',
                                  value: '${_detail!.totalInteractions}',
                                  icon: Icons.forum_outlined,
                                  accent: InterventionsUi.gradientStart,
                                  selected: _section ==
                                      _RapportSection.interactions,
                                  onTap: () => setState(
                                    () => _section =
                                        _RapportSection.interactions,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InterventionsToggleKpiCard(
                                  title: 'Planning',
                                  value: '${_detail!.planning.length}',
                                  icon: Icons.event_note_outlined,
                                  accent: const Color(0xFF7C3AED),
                                  selected:
                                      _section == _RapportSection.planning,
                                  onTap: () => setState(
                                    () => _section = _RapportSection.planning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_section == _RapportSection.interactions)
                            _buildInteractionsSection(_detail!)
                          else
                            _buildPlanningSection(_detail!),
                          if ((_detail!.observationsGenerales).trim().isNotEmpty)
                            ...[
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Observations générales',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(_detail!.observationsGenerales),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInteractionsSection(RapportMensuelDetail detail) {
    final lieux = _lieux(detail);
    if (lieux.isEmpty) {
      return const InterventionsEmptyState(
        title: 'Aucun site rattaché',
        subtitle: 'Aucune interaction pour ce client sur cette période.',
        icon: Icons.forum_outlined,
      );
    }

    return Column(
      children: [
        for (final lieu in lieux) ...[
          _SiteInteractionsCard(
            lieu: lieu,
            adcRows: _rowsForLieu(detail.interactionsAdc, lieu),
            vdcRows: _rowsForLieu(detail.interactionsVdc, lieu),
            refillRows: _rowsForLieu(detail.interactionsRefill, lieu),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPlanningSection(RapportMensuelDetail detail) {
    if (detail.planning.isEmpty) {
      return InterventionsEmptyState(
        title: 'Aucune recharge planifiée',
        subtitle: detail.moisSuivantLabel != null
            ? 'Pour ${detail.moisSuivantLabel}'
            : null,
        icon: Icons.event_note_outlined,
      );
    }

    return Column(
      children: detail.planning
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row.lieu ?? '—'} · ${row.dateLabel ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if ((row.action ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(row.action!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SiteInteractionsCard extends StatelessWidget {
  const _SiteInteractionsCard({
    required this.lieu,
    required this.adcRows,
    required this.vdcRows,
    required this.refillRows,
  });

  final String lieu;
  final List<RapportMensuelLigne> adcRows;
  final List<RapportMensuelLigne> vdcRows;
  final List<RapportMensuelLigne> refillRows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lieu,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _InteractionTypeSection(
              title: 'ADC',
              rows: adcRows,
              emptyMessage: 'Aucun appel de courtoisie sur cette période.',
              showContact: true,
              showRessentiTech: false,
            ),
            const SizedBox(height: 16),
            _InteractionTypeSection(
              title: 'VDC',
              rows: vdcRows,
              emptyMessage: 'Aucune visite de courtoisie sur cette période.',
              showContact: false,
              showRessentiTech: true,
            ),
            const SizedBox(height: 16),
            _InteractionTypeSection(
              title: 'REFILL',
              rows: refillRows,
              emptyMessage: 'Aucune recharge mensuelle sur cette période.',
              showContact: true,
              showRessentiTech: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionTypeSection extends StatelessWidget {
  const _InteractionTypeSection({
    required this.title,
    required this.rows,
    required this.emptyMessage,
    required this.showContact,
    required this.showRessentiTech,
  });

  final String title;
  final List<RapportMensuelLigne> rows;
  final String emptyMessage;
  final bool showContact;
  final bool showRessentiTech;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AromaColors.zinc500,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            emptyMessage,
            style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AromaColors.zinc100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AromaColors.zinc200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.dateLabel ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (showContact && (row.nomContact ?? '').isNotEmpty)
                      InterventionsDetailRow('Contact', row.nomContact!),
                    if ((row.observation ?? '').isNotEmpty &&
                        (row.observation ?? '—') != '—')
                      InterventionsDetailRow('Observation', row.observation!),
                    if (showRessentiTech &&
                        (row.ressentiTechnicien ?? '').isNotEmpty &&
                        (row.ressentiTechnicien ?? '—') != '—')
                      InterventionsDetailRow(
                        'Ressenti tech',
                        row.ressentiTechnicien!,
                      ),
                    if ((row.ressentiClient ?? '').isNotEmpty &&
                        (row.ressentiClient ?? '—') != '—')
                      InterventionsDetailRow(
                        'Ressenti client',
                        row.ressentiClient!,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
