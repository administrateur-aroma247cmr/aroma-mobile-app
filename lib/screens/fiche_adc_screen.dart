import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/adc_exchange_history.dart';
import '../utils/adc_form_logic.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_status_colors.dart';
import '../widgets/interventions/interventions_ui.dart';
import '../widgets/modern_bottom_sheet.dart';
import 'adc_relance_screen.dart';

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

  String _agentLabel() {
    final auth = context.read<AuthProvider>();
    final me = auth.me;
    if (me != null) {
      final name = [
        (me['prenom'] as String? ?? '').trim(),
        (me['nom'] as String? ?? '').trim(),
      ].where((p) => p.isNotEmpty).join(' ');
      if (name.isNotEmpty) return name;
    }
    return auth.userEmail ?? '—';
  }

  String _siteName(ExperienceAdcDetail d) {
    final fromApi = (d.siteName ?? '').trim();
    if (fromApi.isNotEmpty) return fromApi;
    final fallback = (widget.fallbackSiteName ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    return '—';
  }

  String _datePlanifiee(ExperienceAdcDetail d) {
    return formatDateFr(d.datePlanifiee ?? widget.fallbackDatePlanifiee);
  }

  List<AdcExchangeEntry> _exchangeHistory(ExperienceAdcDetail d) {
    return buildAdcExchangeHistory(
      trace: d.actionsTrace,
      relanceTelephoneMessage: d.relanceTelephoneMessage,
      adcRessenti: d.ressenti,
      agentFallback: _agentLabel(),
    );
  }

  Future<void> _openRelance() async {
    final d = _detail;
    if (d == null) return;
    if (!canCreateAdcRelance(d.statut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Relance impossible : statut déjà « Répondu » ou « Non répondu ».',
          ),
        ),
      );
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdcRelanceScreen(
          adcId: d.id,
          initialDetail: d,
          fallbackSiteName: widget.fallbackSiteName,
          fallbackDatePlanifiee: widget.fallbackDatePlanifiee,
        ),
      ),
    );
    if (saved == true && mounted) await _reload();
  }

  void _showExchangeDetail(AdcExchangeEntry e) {
    showModernDetailSheet(
      context: context,
      title: 'Détail de l’échange',
      subtitle: '${e.dateAffiche} · ${e.moyen}',
      theme: ModernSheetThemes.interventions,
      children: [
        _DetailLine('Agent', e.agent),
        _DetailLine('Contact', e.contactLabel),
        if ((e.ressenti ?? '').isNotEmpty) _DetailLine('Ressenti', e.ressenti!),
        const SizedBox(height: 8),
        const Text(
          'Contenu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AromaColors.zinc500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AromaColors.zinc100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AromaColors.zinc200),
          ),
          child: Text(
            adcExchangeDisplayText(e),
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final canRelance = d != null && canCreateAdcRelance(d.statut);

    return Scaffold(
      backgroundColor: InterventionsUi.canvasSoft,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? interventionsErrorState(message: _error!, onRetry: _reload)
              : d == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: InterventionsUi.accent,
                      onRefresh: _reload,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            pinned: true,
                            expandedHeight: 176,
                            backgroundColor: InterventionsUi.gradientStart,
                            foregroundColor: Colors.white,
                            actions: [
                              if (canRelance)
                                TextButton.icon(
                                  onPressed: _openRelance,
                                  icon: Icon(
                                    Icons.add_ic_call_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Relance',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                            ],
                            flexibleSpace: FlexibleSpaceBar(
                              titlePadding: const EdgeInsets.only(
                                left: 56,
                                bottom: 16,
                                right: 100,
                              ),
                              title: Text(
                                d.clientName ?? 'Appel de courtoisie',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              background: Container(
                                decoration: const BoxDecoration(
                                  gradient: InterventionsUi.headerGradient,
                                ),
                                child: SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      56,
                                      20,
                                      52,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Site · ${_siteName(d)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white
                                                .withValues(alpha: 0.92),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            AdcStatutBadge(statut: d.statut),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Planifié · ${_datePlanifiee(d)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _AdcSectionCard(
                                  title: 'Informations',
                                  icon: Icons.info_outline_rounded,
                                  child: Column(
                                    children: [
                                      InterventionsDetailRow(
                                        'Client',
                                        d.clientName ?? '—',
                                      ),
                                      InterventionsDetailRow(
                                        'Site',
                                        _siteName(d),
                                      ),
                                      InterventionsDetailRow(
                                        'Date planifiée',
                                        _datePlanifiee(d),
                                      ),
                                      InterventionsDetailRow(
                                        'Date appel',
                                        formatDateFr(d.dateAppel),
                                      ),
                                      InterventionsDetailRow(
                                        'Statut',
                                        '',
                                        valueWidget:
                                            AdcStatutBadge(statut: d.statut),
                                      ),
                                      InterventionsDetailRow(
                                        'Ressenti',
                                        d.ressenti ?? '—',
                                      ),
                                      if ((d.commentaire ?? '').trim().isNotEmpty)
                                        InterventionsDetailRow(
                                          'Observations',
                                          d.commentaire!.trim(),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _AdcSectionCard(
                                  title: 'Contacts du site',
                                  icon: Icons.people_outline_rounded,
                                  subtitle: '${d.contacts.length} contact(s)',
                                  child: _AdcContactsSection(contacts: d.contacts),
                                ),
                                const SizedBox(height: 12),
                                _AdcSectionCard(
                                  title: 'Historique des échanges',
                                  icon: Icons.history_rounded,
                                  subtitle:
                                      '${_exchangeHistory(d).length} échange(s)',
                                  child: _buildExchangeHistory(d),
                                ),
                                if (canRelance) ...[
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _openRelance,
                                      icon: const Icon(Icons.add_ic_call_rounded),
                                      label: const Text('Créer une relance'),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(52),
                                        backgroundColor: InterventionsUi.accent,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AromaColors.zinc100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AromaColors.zinc200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lock_outline,
                                          size: 20,
                                          color: AromaColors.zinc500,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Relance fermée — statut ${AdcStatutColors.label(d.statut)}.',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AromaColors.zinc500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildExchangeHistory(ExperienceAdcDetail d) {
    final history = _exchangeHistory(d);
    if (history.isEmpty) {
      return const Text(
        'Aucun échange enregistré.',
        style: TextStyle(color: AromaColors.zinc500),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _ExchangeTile(
            entry: history[i],
            isLast: i == history.length - 1,
            onTap: () => _showExchangeDetail(history[i]),
          ),
      ],
    );
  }
}

class _AdcSectionCard extends StatelessWidget {
  const _AdcSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InterventionsUi.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: InterventionsUi.accentMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: InterventionsUi.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AromaColors.zinc900,
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
              ],
            ),
          ),
          const Divider(height: 1, color: AromaColors.zinc100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AdcContactsSection extends StatefulWidget {
  const _AdcContactsSection({required this.contacts});

  final List<AdcContact> contacts;

  @override
  State<_AdcContactsSection> createState() => _AdcContactsSectionState();
}

class _AdcContactsSectionState extends State<_AdcContactsSection> {
  static const _previewCount = 4;
  String _query = '';

  List<AdcContact> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.contacts;
    return widget.contacts.where((c) {
      return c.nomAffiche.toLowerCase().contains(q) ||
          (c.poste ?? '').toLowerCase().contains(q) ||
          (c.telephone ?? '').toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _openAllContacts() {
    showModernBottomSheet<void>(
      context: context,
      builder: (ctx) {
        var sheetQuery = _query;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = sheetQuery.trim().toLowerCase();
            final list = q.isEmpty
                ? widget.contacts
                : widget.contacts.where((c) {
                    return c.nomAffiche.toLowerCase().contains(q) ||
                        (c.poste ?? '').toLowerCase().contains(q) ||
                        (c.telephone ?? '').toLowerCase().contains(q) ||
                        (c.email ?? '').toLowerCase().contains(q);
                  }).toList();

            return ModernBottomSheetShell(
              initialChildSize: 0.85,
              minChildSize: 0.45,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      modernSheetDragHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contacts (${widget.contacts.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: InterventionsUi.softSearchDecoration(
                                hintText: 'Rechercher un contact…',
                              ),
                              onChanged: (v) =>
                                  setSheetState(() => sheetQuery = v),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun contact trouvé.',
                                  style: TextStyle(color: AromaColors.zinc500),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) =>
                                    _ContactTile(contact: list[i]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contacts.isEmpty) {
      return const Text(
        'Aucun contact enregistré.',
        style: TextStyle(color: AromaColors.zinc500),
      );
    }

    final filtered = _filtered;
    final preview = filtered.take(_previewCount).toList();
    final hasMore = filtered.length > _previewCount || widget.contacts.length > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InterventionsUi.softSearchDecoration(
            hintText: 'Rechercher parmi ${widget.contacts.length} contacts…',
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Text(
            'Aucun contact ne correspond à la recherche.',
            style: TextStyle(color: AromaColors.zinc500, fontSize: 13),
          )
        else
          ...preview.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContactTile(contact: c),
            ),
          ),
        if (hasMore || widget.contacts.length > _previewCount) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _openAllContacts,
            icon: const Icon(Icons.unfold_more_rounded, size: 18),
            label: Text(
              _query.isEmpty
                  ? 'Voir les ${widget.contacts.length} contacts'
                  : 'Voir les ${filtered.length} résultats',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: InterventionsUi.accent,
              side: BorderSide(color: InterventionsUi.accentSoft),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final AdcContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InterventionsUi.accentMuted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InterventionsUi.accentSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: InterventionsUi.accentSoft,
            child: Text(
              contact.nomAffiche.isNotEmpty
                  ? contact.nomAffiche[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: InterventionsUi.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nomAffiche,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if ((contact.poste ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      contact.poste!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ),
                if ((contact.telephone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ContactInfoChip(
                    icon: Icons.phone_outlined,
                    text: contact.telephone!,
                  ),
                ],
                if ((contact.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _ContactInfoChip(
                    icon: Icons.mail_outline,
                    text: contact.email!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoChip extends StatelessWidget {
  const _ContactInfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: InterventionsUi.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  const _ExchangeTile({
    required this.entry,
    required this.isLast,
    required this.onTap,
  });

  final AdcExchangeEntry entry;
  final bool isLast;
  final VoidCallback onTap;

  Color get _moyenColor {
    switch (entry.moyen) {
      case 'WhatsApp':
        return const Color(0xFF25D366);
      case 'Téléphone':
        return InterventionsUi.accent;
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _moyenColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AromaColors.zinc200),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AromaColors.zinc200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _moyenColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.moyen,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _moyenColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    entry.dateAffiche,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AromaColors.zinc500,
                                    ),
                                  ),
                                  if (formatAdcRessentiLabel(entry.ressenti) !=
                                      null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ressenti ${formatAdcRessentiLabel(entry.ressenti)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: InterventionsUi.accent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            adcExchangeResumeText(entry),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AromaColors.zinc800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.agent,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AromaColors.zinc500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
