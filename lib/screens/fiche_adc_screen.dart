import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/adc_exchange_history.dart';
import '../utils/format_utils.dart';
import '../widgets/interventions/interventions_ui.dart';

class FicheAdcScreen extends StatefulWidget {
  const FicheAdcScreen({
    super.key,
    required this.adcId,
    this.fallbackSiteName,
    this.fallbackDatePlanifiee,
  });

  final String adcId;
  final String? fallbackSiteName;
  final String? fallbackDatePlanifiee;

  @override
  State<FicheAdcScreen> createState() => _FicheAdcScreenState();
}

class _FicheAdcScreenState extends State<FicheAdcScreen> {
  bool _loading = true;
  String? _error;
  ExperienceAdcDetail? _detail;

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
      final detail = await api.getExperienceAdcDetail(widget.adcId);
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

  String _siteName(ExperienceAdcDetail d) {
    final fromApi = (d.siteName ?? '').trim();
    if (fromApi.isNotEmpty) return fromApi;
    final fallback = (widget.fallbackSiteName ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    return '—';
  }

  String _datePlanifiee(ExperienceAdcDetail d) {
    final raw = d.datePlanifiee ?? widget.fallbackDatePlanifiee;
    return formatDateFr(raw);
  }

  String _interventionSubtitle(ExperienceAdcDetail d) {
    final parts = <String>[];
    if ((d.interventionRef ?? '').isNotEmpty) parts.add(d.interventionRef!);
    if ((d.interventionDate ?? '').isNotEmpty) {
      parts.add(formatDateFr(d.interventionDate));
    }
    return parts.join(' · ');
  }

  List<AdcExchangeEntry> _exchangeHistory(ExperienceAdcDetail d) {
    return buildAdcExchangeHistory(
      trace: d.actionsTrace,
      relanceTelephoneMessage: d.relanceTelephoneMessage,
      adcRessenti: d.ressenti,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: Text(_detail?.titreAffiche ?? 'Fiche ADC'),
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
                            'Fiche ADC — ${_detail!.clientName ?? '—'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Site · ${_siteName(_detail!)}',
                            style: const TextStyle(
                              color: AromaColors.zinc500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date planifiée · ${_datePlanifiee(_detail!)}',
                            style: const TextStyle(
                              color: AromaColors.zinc500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_interventionSubtitle(_detail!).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _interventionSubtitle(_detail!),
                              style: const TextStyle(
                                color: AromaColors.zinc500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _SectionCard(
                            title: 'Informations',
                            children: [
                              InterventionsDetailRow(
                                'Client',
                                _detail!.clientName ?? '—',
                              ),
                              InterventionsDetailRow(
                                'Site',
                                _siteName(_detail!),
                              ),
                              InterventionsDetailRow(
                                'Date planifiée',
                                _datePlanifiee(_detail!),
                              ),
                              InterventionsDetailRow(
                                'Date appel',
                                formatDateFr(_detail!.dateAppel),
                              ),
                              InterventionsDetailRow(
                                'Statut',
                                '',
                                valueWidget: AdcStatutBadge(statut: _detail!.statut),
                              ),
                              InterventionsDetailRow(
                                'Ressenti',
                                _detail!.ressenti ?? '—',
                              ),
                              if ((_detail!.commentaire ?? '').trim().isNotEmpty)
                                InterventionsDetailRow(
                                  'Observations',
                                  _detail!.commentaire!.trim(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Contacts du site',
                            subtitle:
                                '${_detail!.contacts.length} contact(s)',
                            children: _detail!.contacts.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'Aucun contact enregistré.',
                                        style: TextStyle(
                                          color: AromaColors.zinc500,
                                        ),
                                      ),
                                    ),
                                  ]
                                : _detail!.contacts
                                    .map(
                                      (c) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.nomAffiche,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if ((c.poste ?? '').isNotEmpty)
                                              Text(
                                                c.poste!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AromaColors.zinc500,
                                                ),
                                              ),
                                            if ((c.telephone ?? '').isNotEmpty)
                                              Text(
                                                c.telephone!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            if ((c.email ?? '').isNotEmpty)
                                              Text(
                                                c.email!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Historique des échanges',
                            subtitle:
                                '${_exchangeHistory(_detail!).length} échange(s)',
                            children: _buildExchangeHistory(_detail!),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildExchangeHistory(ExperienceAdcDetail d) {
    final history = _exchangeHistory(d);
    if (history.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Aucun échange enregistré.',
            style: TextStyle(color: AromaColors.zinc500),
          ),
        ),
      ];
    }

    return history
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.dateAffiche} · ${e.moyen}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (e.contactLabel != '—')
                  Text(
                    e.contactLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AromaColors.zinc500,
                    ),
                  ),
                if (e.agent != '—')
                  Text(
                    'Par ${e.agent}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AromaColors.zinc500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(e.resume),
                if ((e.notesAppel ?? '').trim().isNotEmpty &&
                    e.notesAppel != e.resume)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      e.notesAppel!.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ),
                if ((e.ressenti ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Ressenti : ${e.ressenti}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
