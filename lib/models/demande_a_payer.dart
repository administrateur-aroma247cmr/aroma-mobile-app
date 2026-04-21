class DemandeJustificatif {
  DemandeJustificatif({required this.name, this.path, this.size});

  final String name;
  final String? path;
  final int? size;

  static DemandeJustificatif? tryParse(dynamic e) {
    if (e is! Map) return null;
    final m = Map<String, dynamic>.from(e);
    final name = m['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final path = m['path'];
    final size = m['size'];
    return DemandeJustificatif(
      name: name.trim(),
      path: path is String ? path.trim() : null,
      size: size is int ? size : int.tryParse('$size'),
    );
  }
}

class DemandeAPayer {
  DemandeAPayer({
    required this.id,
    required this.client,
    required this.raisonBonCommande,
    required this.montantDemande,
    this.origine,
    this.auteur,
    this.statut,
    this.dateADecaisser,
    this.montantAttendu,
    this.raisonBonTransport,
    this.justificatifs = const [],
  });

  final String id;
  final String client;
  final String raisonBonCommande;
  final double montantDemande;
  final String? origine;
  final String? auteur;
  final String? statut;
  final String? dateADecaisser;
  final double? montantAttendu;
  final String? raisonBonTransport;
  final List<DemandeJustificatif> justificatifs;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  static String? _dateKey(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
      if (m != null) {
        return '${m[1]}-${m[2]}-${m[3]}';
      }
      final t = DateTime.tryParse(s);
      if (t != null) {
        return '${t.year.toString().padLeft(4, '0')}-'
            '${t.month.toString().padLeft(2, '0')}-'
            '${t.day.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  factory DemandeAPayer.fromJson(Map<String, dynamic> m) {
    final rawJ = m['justificatifs'];
    final pj = <DemandeJustificatif>[];
    if (rawJ is List) {
      for (final e in rawJ) {
        final j = DemandeJustificatif.tryParse(e);
        if (j != null) pj.add(j);
      }
    }
    return DemandeAPayer(
      id: '${m['id']}',
      client: '${m['client'] ?? ''}',
      raisonBonCommande: '${m['raison_bon_commande'] ?? ''}',
      montantDemande: _num(m['montant_demande']),
      origine: m['origine'] is String ? (m['origine'] as String).trim() : null,
      auteur: m['auteur'] is String ? (m['auteur'] as String).trim() : null,
      statut: m['statut'] is String ? (m['statut'] as String).trim() : null,
      dateADecaisser: _dateKey(m['date_a_decaisser']),
      montantAttendu: m['montant_attendu'] != null ? _num(m['montant_attendu']) : null,
      raisonBonTransport: m['raison_bon_transport'] is String
          ? (m['raison_bon_transport'] as String).trim()
          : null,
      justificatifs: pj,
    );
  }
}
