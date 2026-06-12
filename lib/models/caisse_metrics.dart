class MaCaisseAccess {
  MaCaisseAccess({
    required this.canAccess,
    required this.isDirection,
    required this.isDesignatedCaissier,
    required this.isDesignatedSuperviseurFermetureDraft,
  });

  final bool canAccess;
  final bool isDirection;
  final bool isDesignatedCaissier;
  final bool isDesignatedSuperviseurFermetureDraft;

  factory MaCaisseAccess.fromJson(Map<String, dynamic> m) {
    return MaCaisseAccess(
      canAccess: m['can_access'] == true,
      isDirection: m['is_direction'] == true,
      isDesignatedCaissier: m['is_designated_caissier'] == true,
      isDesignatedSuperviseurFermetureDraft:
          m['is_designated_superviseur_fermeture_draft'] == true,
    );
  }
}

class CaisseMetrics {
  CaisseMetrics({
    required this.dateJour,
    this.ouvertureEffectueeAujourdhui,
    this.fermetureEffectueeAujourdhui,
    this.journeeCaisseEquilibreeAujourdhui,
    this.sessionCaisseOuverteAujourdhui,
    required this.soldeOuvertureEstimeFcfa,
    required this.soldeCaisseActuelFcfa,
    required this.netMouvementsCaisseAujourdhuiFcfa,
    required this.attenteFinJourneeFcfa,
    required this.encaissementJourFcfa,
    required this.paiementsSortieJourFcfa,
    required this.rentreesEntreeJourFcfa,
    required this.soldesComptesFcfa,
  });

  final String dateJour;
  final bool? ouvertureEffectueeAujourdhui;
  final bool? fermetureEffectueeAujourdhui;
  final bool? journeeCaisseEquilibreeAujourdhui;
  final bool? sessionCaisseOuverteAujourdhui;
  final double soldeOuvertureEstimeFcfa;
  final double soldeCaisseActuelFcfa;
  final double netMouvementsCaisseAujourdhuiFcfa;
  final double attenteFinJourneeFcfa;
  final double encaissementJourFcfa;
  final CaisseCanalMontants paiementsSortieJourFcfa;
  final CaisseCanalMontants rentreesEntreeJourFcfa;
  final Map<String, double> soldesComptesFcfa;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory CaisseMetrics.fromJson(Map<String, dynamic> m) {
    final soldesRaw = m['soldes_comptes_fcfa'];
    final soldes = <String, double>{};
    if (soldesRaw is Map) {
      soldesRaw.forEach((k, v) {
        soldes['$k'] = _num(v);
      });
    }
    return CaisseMetrics(
      dateJour: '${m['date_jour'] ?? ''}',
      ouvertureEffectueeAujourdhui: m['ouverture_effectuee_aujourdhui'] as bool?,
      fermetureEffectueeAujourdhui: m['fermeture_effectuee_aujourdhui'] as bool?,
      journeeCaisseEquilibreeAujourdhui:
          m['journee_caisse_equilibree_aujourdhui'] as bool?,
      sessionCaisseOuverteAujourdhui:
          m['session_caisse_ouverte_aujourdhui'] as bool?,
      soldeOuvertureEstimeFcfa: _num(m['solde_ouverture_estime_fcfa']),
      soldeCaisseActuelFcfa: _num(m['solde_caisse_actuel_fcfa']),
      netMouvementsCaisseAujourdhuiFcfa:
          _num(m['net_mouvements_caisse_aujourdhui_fcfa']),
      attenteFinJourneeFcfa: _num(m['attente_fin_journee_fcfa']),
      encaissementJourFcfa: _num(m['encaissement_jour_fcfa']),
      paiementsSortieJourFcfa: CaisseCanalMontants.fromJson(
        m['paiements_sortie_jour_fcfa'] is Map
            ? Map<String, dynamic>.from(m['paiements_sortie_jour_fcfa'] as Map)
            : const {},
      ),
      rentreesEntreeJourFcfa: CaisseCanalMontants.fromJson(
        m['rentrees_entree_jour_fcfa'] is Map
            ? Map<String, dynamic>.from(m['rentrees_entree_jour_fcfa'] as Map)
            : const {},
      ),
      soldesComptesFcfa: soldes,
    );
  }
}

class CaisseCanalMontants {
  CaisseCanalMontants({
    required this.especes,
    required this.momo,
    required this.om,
    required this.banque,
    required this.total,
  });

  final double especes;
  final double momo;
  final double om;
  final double banque;
  final double total;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory CaisseCanalMontants.fromJson(Map<String, dynamic> m) {
    return CaisseCanalMontants(
      especes: _num(m['especes']),
      momo: _num(m['momo']),
      om: _num(m['om']),
      banque: _num(m['banque']),
      total: _num(m['total']),
    );
  }
}

class CaisseRecapPerso {
  CaisseRecapPerso({
    required this.total,
    required this.brouillon,
    required this.enAttente,
    required this.paye,
    required this.montantPayeFcfa,
  });

  final int total;
  final int brouillon;
  final int enAttente;
  final int paye;
  final double montantPayeFcfa;
}
