import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recouvrement.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/compta/compta_ui.dart';
import '../widgets/modern_bottom_sheet.dart';

class FicheRecouvrementScreen extends StatefulWidget {
  const FicheRecouvrementScreen({super.key, required this.facture});

  final FactureRecouvrementItem facture;

  @override
  State<FicheRecouvrementScreen> createState() =>
      _FicheRecouvrementScreenState();
}

class _FicheRecouvrementScreenState extends State<FicheRecouvrementScreen> {
  bool _loading = true;
  String? _error;
  RecouvrementDetail? _detail;

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
      final detail = await api.getRecouvrementDetail(widget.facture.id);
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

  List<_RelanceEchange> get _exchanges {
    final trace = _detail?.actionsTrace ?? const [];
    return _RelanceEchange.fromTrace(trace);
  }

  void _showExchangeDetail(_RelanceEchange e) {
    showModernDetailSheet(
      context: context,
      title: 'Échange ${e.moyen}',
      subtitle: e.dateLabel,
      theme: ModernSheetThemes.compta,
      titleTrailing: _MoyenBadge(moyen: e.moyen),
      children: [
        _DetailLine('Agent', e.agent),
        _DetailLine('Contact', e.contact),
        if (e.ressenti != null && e.ressenti!.isNotEmpty)
          _DetailLine('Ressenti', e.ressenti!),
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
            e.contenu,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AromaColors.zinc800,
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageDetail(String title, String content, IconData icon, Color color) {
    showModernDetailSheet(
      context: context,
      title: title,
      theme: ModernSheetThemes.compta,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AromaColors.zinc200),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AromaColors.zinc800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facture;
    final enRetard = f.joursRetard > 0;

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: 168,
                        backgroundColor: ComptaUi.gradientStart,
                        foregroundColor: Colors.white,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(
                            left: 56,
                            bottom: 16,
                            right: 16,
                          ),
                          title: Text(
                            f.nomClient,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          background: Container(
                            decoration: const BoxDecoration(
                              gradient: ComptaUi.gradient,
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 56, 20, 52),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.refFacture.trim().isNotEmpty
                                          ? f.refFacture
                                          : 'Facture recouvrement',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          fmtFcfa(f.montant),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (enRetard)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              '${f.joursRetard} j retard',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _ReadOnlyBanner(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionCard(
                                title: 'Détails facture',
                                icon: Icons.receipt_long_outlined,
                                child: Column(
                                  children: [
                                    _InfoGrid(
                                      items: [
                                        _InfoItem('Client', f.nomClient),
                                        _InfoItem(
                                          'N° facture',
                                          f.refFacture.trim().isNotEmpty
                                              ? f.refFacture
                                              : '—',
                                        ),
                                        _InfoItem('Montant', fmtFcfa(f.montant)),
                                        _InfoItem(
                                          'Date attendue',
                                          formatDateFr(f.dateAttendu),
                                        ),
                                        if (enRetard)
                                          _InfoItem(
                                            'Jours de retard',
                                            '${f.joursRetard}',
                                            accent: const Color(0xFFB91C1C),
                                          ),
                                        if (f.statut != null)
                                          _InfoItem('Statut', f.statut!),
                                        if (_detail?.assigneNom != null)
                                          _InfoItem(
                                            'Assigné à',
                                            _detail!.assigneNom!,
                                          ),
                                        if (_detail?.nombreRelances != null)
                                          _InfoItem(
                                            'Nombre de relances',
                                            '${_detail!.nombreRelances}',
                                          ),
                                        if (_detail?.dateDerniereRelance != null)
                                          _InfoItem(
                                            'Dernière relance',
                                            formatDateFr(
                                              _detail!.dateDerniereRelance,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'Messages de relance',
                                subtitle: 'Derniers contenus enregistrés — lecture seule',
                                icon: Icons.mail_outline_rounded,
                                child: _RelanceMessages(
                                  mail: _detail?.relanceMailMessage,
                                  whatsapp: _detail?.relanceWhatsappMessage,
                                  telephone: _detail?.relanceTelephoneMessage,
                                  onOpen: _showMessageDetail,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SectionCard(
                                title: 'Historique des échanges',
                                subtitle:
                                    '${_exchanges.length} relance(s) enregistrée(s)',
                                icon: Icons.history_rounded,
                                child: _exchanges.isEmpty
                                    ? const _EmptyHistorique()
                                    : Column(
                                        children: [
                                          for (var i = 0; i < _exchanges.length; i++)
                                            _ExchangeTimelineTile(
                                              exchange: _exchanges[i],
                                              isLast: i == _exchanges.length - 1,
                                              onTap: () => _showExchangeDetail(
                                                _exchanges[i],
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 20,
            color: ComptaUi.gradientStart.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Consultation seule sur mobile — aucun envoi ni modification.',
              style: TextStyle(
                fontSize: 13,
                color: ComptaUi.gradientStart.withValues(alpha: 0.95),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AromaColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ComptaUi.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: ComptaUi.accent),
                ),
                const SizedBox(width: 10),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value, {this.accent});

  final String label;
  final String value;
  final Color? accent;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCol = c.maxWidth >= 360;
        if (!twoCol) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCell(item: item),
                  ),
                )
                .toList(),
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _InfoCell(item: items[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < items.length
                        ? _InfoCell(item: items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AromaColors.zinc100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              color: AromaColors.zinc500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: item.accent ?? AromaColors.zinc900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelanceMessages extends StatelessWidget {
  const _RelanceMessages({
    required this.mail,
    required this.whatsapp,
    required this.telephone,
    required this.onOpen,
  });

  final String? mail;
  final String? whatsapp;
  final String? telephone;
  final void Function(String title, String content, IconData icon, Color color)
      onOpen;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];

    void addBlock(
      String title,
      String? text,
      IconData icon,
      Color color,
    ) {
      final content = text?.trim();
      if (content == null || content.isEmpty) return;
      blocks.add(
        _MessagePreviewCard(
          title: title,
          preview: content,
          icon: icon,
          color: color,
          onTap: () => onOpen(title, content, icon, color),
        ),
      );
      blocks.add(const SizedBox(height: 8));
    }

    addBlock(
      'Relance mail',
      mail,
      Icons.email_outlined,
      const Color(0xFF2563EB),
    );
    addBlock(
      'Relance WhatsApp',
      whatsapp,
      Icons.chat_outlined,
      const Color(0xFF25D366),
    );
    addBlock(
      'Relance téléphone',
      telephone,
      Icons.phone_outlined,
      const Color(0xFF52525B),
    );

    if (blocks.isEmpty) {
      return const _EmptyHistorique(
        message: 'Aucun message de relance enregistré.',
      );
    }
    if (blocks.last is SizedBox) blocks.removeLast();
    return Column(children: blocks);
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({
    required this.title,
    required this.preview,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String preview;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final short = preview.length > 120
        ? '${preview.substring(0, 120).trim()}…'
        : preview;

    return Material(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        short,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AromaColors.zinc500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AromaColors.zinc500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExchangeTimelineTile extends StatelessWidget {
  const _ExchangeTimelineTile({
    required this.exchange,
    required this.isLast,
    required this.onTap,
  });

  final _RelanceEchange exchange;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: exchange.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: exchange.color.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AromaColors.zinc200,
                    ),
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
                            children: [
                              _MoyenBadge(moyen: exchange.moyen),
                              const Spacer(),
                              Text(
                                exchange.dateLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AromaColors.zinc500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exchange.resume,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AromaColors.zinc800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${exchange.agent} · ${exchange.contact}',
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

class _MoyenBadge extends StatelessWidget {
  const _MoyenBadge({required this.moyen});

  final String moyen;

  @override
  Widget build(BuildContext context) {
    final color = switch (moyen) {
      'WhatsApp' => const Color(0xFF25D366),
      'Téléphone' => const Color(0xFF52525B),
      _ => const Color(0xFF2563EB),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        moyen,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyHistorique extends StatelessWidget {
  const _EmptyHistorique({this.message = 'Aucun échange enregistré.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 20,
            color: AromaColors.zinc500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AromaColors.zinc500),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AromaColors.zinc500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AromaColors.zinc900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelanceEchange {
  _RelanceEchange({
    required this.moyen,
    required this.agent,
    required this.contact,
    required this.contenu,
    required this.resume,
    required this.dateLabel,
    this.ressenti,
  });

  final String moyen;
  final String agent;
  final String contact;
  final String contenu;
  final String resume;
  final String dateLabel;
  final String? ressenti;

  Color get color => switch (moyen) {
        'WhatsApp' => const Color(0xFF25D366),
        'Téléphone' => const Color(0xFF52525B),
        _ => const Color(0xFF2563EB),
      };

  static List<_RelanceEchange> fromTrace(List<Map<String, dynamic>> trace) {
    final entries = <_RelanceEchange>[];
    for (final e in trace) {
      final canal = '${e['canal'] ?? e['moyen'] ?? 'Mail'}'.trim();
      final moyen = switch (canal) {
        'WhatsApp' || 'Téléphone' || 'Mail' => canal,
        _ => 'Mail',
      };
      final date = '${e['date'] ?? ''}'.trim();
      final heure = '${e['heure'] ?? ''}'.trim();
      final dateLabel = date.isEmpty
          ? '—'
          : heure.isNotEmpty
              ? '$date $heure'
              : formatDateFr(date);

      var contenu = '${e['message'] ?? e['description'] ?? e['resume'] ?? e['contenu'] ?? ''}'
          .trim();
      String? ressenti;

      if (moyen == 'Téléphone' && contenu.startsWith('{')) {
        try {
          final decoded = _parsePhoneJson(contenu);
          contenu = decoded.message;
          ressenti = decoded.ressenti;
        } catch (_) {}
      }

      if (contenu.isEmpty) contenu = '—';

      entries.add(
        _RelanceEchange(
          moyen: moyen,
          agent: '${e['auteur'] ?? e['agent'] ?? '—'}'.trim(),
          contact: '${e['contact'] ?? '—'}'.trim(),
          contenu: contenu,
          resume: contenu.length > 120
              ? '${contenu.substring(0, 120).trim()}…'
              : contenu,
          dateLabel: dateLabel,
          ressenti: ressenti ??
              ('${e['ressenti'] ?? ''}'.trim().isNotEmpty
                  ? '${e['ressenti']}'
                  : null),
        ),
      );
    }

    entries.sort((a, b) => b.dateLabel.compareTo(a.dateLabel));
    return entries;
  }

  static _PhonePayload _parsePhoneJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        return _PhonePayload(
          message: '${m['message'] ?? raw}'.trim(),
          ressenti: m['ressenti']?.toString().trim(),
        );
      }
    } catch (_) {}
    return _PhonePayload(message: raw.trim());
  }
}

class _PhonePayload {
  const _PhonePayload({required this.message, this.ressenti});

  final String message;
  final String? ressenti;
}
