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
    this.valideParHierarchie,
    this.payePar,
    this.payeAt,
    this.createdAt,
    this.updatedAt,
    this.retour,
    this.montantEspece,
    this.montantMomo,
    this.montantOm,
    this.montantCheque,
    this.attenteRetourCaisse,
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
  final String? valideParHierarchie;
  final String? payePar;
  final String? payeAt;
  final String? createdAt;
  final String? updatedAt;
  final String? retour;
  final double? montantEspece;
  final double? montantMomo;
  final double? montantOm;
  final double? montantCheque;
  final String? attenteRetourCaisse;

  double get montantDonneTotal {
    var sum = 0.0;
    for (final v in [montantEspece, montantMomo, montantOm, montantCheque]) {
      if (v != null) sum += v;
    }
    return sum;
  }

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
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    String? retourStr(dynamic v) {
      if (v == null || v == '') return null;
      return '$v';
    }

    return DemandeAPayer(
      id: '${m['id']}',
      client: '${m['client'] ?? ''}',
      raisonBonCommande: '${m['raison_bon_commande'] ?? ''}',
      montantDemande: _num(m['montant_demande']),
      origine: str(m['origine']),
      auteur: str(m['auteur']),
      statut: str(m['statut']),
      dateADecaisser: _dateKey(m['date_a_decaisser']),
      montantAttendu: m['montant_attendu'] != null ? _num(m['montant_attendu']) : null,
      raisonBonTransport: str(m['raison_bon_transport']),
      justificatifs: pj,
      valideParHierarchie: str(m['valide_par_hierarchie']),
      payePar: str(m['paye_par']),
      payeAt: str(m['paye_at']),
      createdAt: str(m['created_at']),
      updatedAt: str(m['updated_at']),
      retour: retourStr(m['retour']),
      montantEspece: m['montant_espece'] != null ? _num(m['montant_espece']) : null,
      montantMomo: m['montant_momo'] != null ? _num(m['montant_momo']) : null,
      montantOm: m['montant_om'] != null ? _num(m['montant_om']) : null,
      montantCheque: m['montant_cheque'] != null ? _num(m['montant_cheque']) : null,
      attenteRetourCaisse: str(m['attente_retour_caisse']),
    );
  }
}
