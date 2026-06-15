import 'package:flutter/material.dart';

import '../../models/intervention.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';

Future<void> showTransportDetailSheet(
  BuildContext context,
  TransportIntervention transport,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TransportDetailSheet(transport: transport),
  );
}

class _TransportDetailSheet extends StatelessWidget {
  const _TransportDetailSheet({required this.transport});

  final TransportIntervention transport;

  static const _accent = Color(0xFF0891B2);
  static const _accentEnd = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final title = transport.titreAffiche;
    final date = formatDateFr(transport.dateTransport);
    final ville = (transport.ville ?? '').trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: transport.points.isEmpty ? 0.52 : 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 16 + bottom),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AromaColors.zinc200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HeaderCard(
                  title: title,
                  date: date,
                  ville: ville.isEmpty ? null : ville,
                  technicien: transport.technicienNom,
                  trajetsCount: transport.pointsCount,
                  montantTotal: transport.montantTotal,
                ),
              ),
              const SizedBox(height: 16),
              if ((transport.raisonDeplacement ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _InfoTile(
                    icon: Icons.notes_rounded,
                    label: 'Raison du déplacement',
                    value: transport.raisonDeplacement!.trim(),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: _accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Détail des trajets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${transport.pointsCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (transport.points.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyTrajetsCard(),
                )
              else
                ...transport.points.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _TrajetCard(
                      index: entry.key + 1,
                      point: entry.value,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.date,
    this.ville,
    this.technicien,
    required this.trajetsCount,
    this.montantTotal,
  });

  final String title;
  final String date;
  final String? ville;
  final String? technicien;
  final int trajetsCount;
  final double? montantTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _TransportDetailSheet._accent,
            _TransportDetailSheet._accentEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _TransportDetailSheet._accent.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (date != '—') date,
                          ?ville,
                        ].join(' · '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((technicien ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      technicien!.trim(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    label: 'Trajets',
                    value: '$trajetsCount',
                    icon: Icons.alt_route_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderStat(
                    label: 'Total',
                    value: montantTotal != null
                        ? fmtFcfa(montantTotal)
                        : '—',
                    icon: Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AromaColors.zinc100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _TransportDetailSheet._accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _TransportDetailSheet._accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrajetsCard extends StatelessWidget {
  const _EmptyTrajetsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AromaColors.zinc100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AromaColors.zinc200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.route_outlined,
            size: 36,
            color: AromaColors.zinc400,
          ),
          const SizedBox(height: 10),
          Text(
            'Aucun trajet enregistré',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Les points de déplacement apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AromaColors.zinc500),
          ),
        ],
      ),
    );
  }
}

class _TrajetCard extends StatelessWidget {
  const _TrajetCard({required this.index, required this.point});

  final int index;
  final TransportPoint point;

  @override
  Widget build(BuildContext context) {
    final dep = point.departAffiche.isEmpty ? '—' : point.departAffiche;
    final arr = point.arriveeAffiche.isEmpty ? '—' : point.arriveeAffiche;

    return Container(
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AromaColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _TransportDetailSheet._accent,
                        _TransportDetailSheet._accentEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point.trajetLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AromaColors.zinc900,
                    ),
                  ),
                ),
                if (point.montant != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fmtFcfa(point.montant),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _RouteStop(
              label: 'Départ',
              place: dep,
              client: point.clientNomDepart,
              isStart: true,
              isLast: false,
            ),
            _RouteStop(
              label: 'Arrivée',
              place: arr,
              client: point.clientNom,
              isStart: false,
              isLast: true,
            ),
            if ((point.sousDesignation ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AromaColors.zinc100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  point.sousDesignation!.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AromaColors.zinc800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.place,
    this.client,
    required this.isStart,
    required this.isLast,
  });

  final String label;
  final String place;
  final String? client;
  final bool isStart;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isStart
        ? _TransportDetailSheet._accent
        : const Color(0xFF059669);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor.withValues(alpha: 0.25),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _TransportDetailSheet._accent.withValues(alpha: 0.5),
                            const Color(0xFF059669).withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc900,
                    ),
                  ),
                  if ((client ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      client!.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
