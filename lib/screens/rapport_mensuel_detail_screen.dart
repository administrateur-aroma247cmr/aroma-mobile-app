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

  List<RapportMensuelLigne> get _interactionRows {
    final d = _detail!;
    return [...d.interactionsAdc, ...d.interactionsVdc, ...d.interactionsRefill];
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
                                  selected:
                                      _section == _RapportSection.interactions,
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
                          if (_section == _RapportSection.interactions) ...[
                            if (_detail!.interactionsAdc.isNotEmpty) ...[
                              _InteractionGroup(
                                title: 'ADC',
                                rows: _detail!.interactionsAdc,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_detail!.interactionsVdc.isNotEmpty) ...[
                              _InteractionGroup(
                                title: 'VDC',
                                rows: _detail!.interactionsVdc,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_detail!.interactionsRefill.isNotEmpty) ...[
                              _InteractionGroup(
                                title: 'REFILL',
                                rows: _detail!.interactionsRefill,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_interactionRows.isEmpty)
                              const InterventionsEmptyState(
                                title: 'Aucune interaction ce mois',
                                icon: Icons.forum_outlined,
                              ),
                          ] else ...[
                            if (_detail!.planning.isEmpty)
                              InterventionsEmptyState(
                                title: 'Aucune recharge planifiée',
                                subtitle: _detail!.moisSuivantLabel != null
                                    ? 'Pour ${_detail!.moisSuivantLabel}'
                                    : null,
                                icon: Icons.event_note_outlined,
                              )
                            else
                              ..._detail!.planning.map(
                                (row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${row.lieu ?? '—'} · ${row.dateLabel ?? '—'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                              ),
                          ],
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
}

class _InteractionGroup extends StatelessWidget {
  const _InteractionGroup({required this.title, required this.rows});

  final String title;
  final List<RapportMensuelLigne> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AromaColors.zinc500,
              ),
        ),
        const SizedBox(height: 8),
        ...rows.map(
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
                    if ((row.nomContact ?? '').isNotEmpty)
                      InterventionsDetailRow('Contact', row.nomContact!),
                    if ((row.ressentiClient ?? '').isNotEmpty)
                      InterventionsDetailRow(
                        'Ressenti client',
                        row.ressentiClient!,
                      ),
                    if ((row.ressentiTechnicien ?? '').isNotEmpty)
                      InterventionsDetailRow(
                        'Ressenti tech',
                        row.ressentiTechnicien!,
                      ),
                    if ((row.observation ?? '').isNotEmpty)
                      InterventionsDetailRow('Observation', row.observation!),
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
