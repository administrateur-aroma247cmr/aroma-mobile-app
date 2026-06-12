class RecouvrementPage {
  RecouvrementPage({
    required this.montantRetard,
    required this.montantAttendu,
    required this.facturesRetard,
    required this.facturesAttendu,
  });

  final double montantRetard;
  final double montantAttendu;
  final List<FactureRecouvrementItem> facturesRetard;
  final List<FactureRecouvrementItem> facturesAttendu;

  int get nbFactures =>
      facturesRetard.length + facturesAttendu.length;

  double get montantSolde => montantRetard + montantAttendu;

  Set<String> get clientIds {
    final ids = <String>{};
    for (final f in [...facturesRetard, ...facturesAttendu]) {
      if (f.idClient.isNotEmpty) ids.add(f.idClient);
    }
    return ids;
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory RecouvrementPage.fromJson(Map<String, dynamic> m) {
    List<FactureRecouvrementItem> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => FactureRecouvrementItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    return RecouvrementPage(
      montantRetard: _num(m['montant_retard']),
      montantAttendu: _num(m['montant_attendu']),
      facturesRetard: parseList(m['factures_retard']),
      facturesAttendu: parseList(m['factures_attendu']),
    );
  }
}

class FactureRecouvrementItem {
  FactureRecouvrementItem({
    required this.id,
    required this.idClient,
    required this.nomClient,
    required this.refFacture,
    required this.montant,
    required this.joursRetard,
    this.dateAttendu,
    this.statut,
    this.nombreRelances,
  });

  final String id;
  final String idClient;
  final String nomClient;
  final String refFacture;
  final double montant;
  final int joursRetard;
  final String? dateAttendu;
  final String? statut;
  final int? nombreRelances;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory FactureRecouvrementItem.fromJson(Map<String, dynamic> m) {
    return FactureRecouvrementItem(
      id: '${m['id']}',
      idClient: '${m['id_client'] ?? ''}',
      nomClient: '${m['nom_client'] ?? ''}',
      refFacture: '${m['ref_facture'] ?? ''}',
      montant: _num(m['montant']),
      joursRetard: (m['jours_retard'] as num?)?.toInt() ?? 0,
      dateAttendu:
          m['date_attendu'] is String ? m['date_attendu'] as String : null,
      statut: m['statut'] is String ? m['statut'] as String : null,
      nombreRelances: (m['nombre_relances'] as num?)?.toInt(),
    );
  }
}

class RecapComptable {
  RecapComptable({
    required this.depenseMois,
    required this.recetteMois,
    required this.resteRecouvrirMois,
  });

  final double depenseMois;
  final double recetteMois;
  final double resteRecouvrirMois;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory RecapComptable.fromJson(Map<String, dynamic> m) {
    return RecapComptable(
      depenseMois: _num(m['depense_mois']),
      recetteMois: _num(m['recette_mois']),
      resteRecouvrirMois: _num(m['reste_recouvrir_mois']),
    );
  }
}

class RecouvrementKpiBundle {
  RecouvrementKpiBundle({
    required this.page,
    required this.montantEncours,
    required this.nbFacturesRetard,
    required this.nbFacturesAttendu,
    required this.nbRelancesTotal,
    required this.montantRecouvreMois,
    this.recetteMois,
    this.depenseMois,
    this.demandesMontantMois,
  });

  final RecouvrementPage page;
  final double montantEncours;
  final int nbFacturesRetard;
  final int nbFacturesAttendu;
  final int nbRelancesTotal;
  final double montantRecouvreMois;
  final double? recetteMois;
  final double? depenseMois;
  final double? demandesMontantMois;

  int get nbFacturesARecouvrer => nbFacturesRetard + nbFacturesAttendu;

  int get nbClientsARecouvrer => page.clientIds.length;
}
