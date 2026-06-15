class KpiSeriesPoint {
  KpiSeriesPoint({required this.label, required this.value});

  final String label;
  final double value;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static List<KpiSeriesPoint> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => KpiSeriesPoint(
            label: '${e['label'] ?? ''}',
            value: _num(e['value']),
          ),
        )
        .where((e) => e.label.isNotEmpty)
        .toList();
  }
}

class KpiTrendPoint {
  KpiTrendPoint({required this.mois, required this.value});

  final String mois;
  final double value;

  static List<KpiTrendPoint> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => KpiTrendPoint(
            mois: '${e['mois'] ?? ''}',
            value: KpiSeriesPoint._num(e['value']),
          ),
        )
        .where((e) => e.mois.isNotEmpty)
        .toList();
  }
}

class AnalyticsGlobalDashboard {
  AnalyticsGlobalDashboard({
    required this.periode,
    required this.periodeLabel,
    required this.synthese,
    this.parc,
    required this.interventions,
    required this.stock,
    required this.comptabilite,
    required this.recouvrement,
    required this.facturation,
    required this.commercial,
    required this.taches,
  });

  final String periode;
  final String periodeLabel;
  final AnalyticsSynthese synthese;
  final AnalyticsParcKpi? parc;
  final AnalyticsInterventionsKpi interventions;
  final AnalyticsStockKpi stock;
  final AnalyticsComptabiliteKpi comptabilite;
  final AnalyticsRecouvrementKpi recouvrement;
  final AnalyticsFacturationKpi facturation;
  final AnalyticsCommercialKpi commercial;
  final AnalyticsTachesKpi taches;

  factory AnalyticsGlobalDashboard.fromJson(Map<String, dynamic> m) {
    return AnalyticsGlobalDashboard(
      periode: '${m['periode'] ?? ''}',
      periodeLabel: '${m['periode_label'] ?? ''}',
      synthese: AnalyticsSynthese.fromJson(
        m['synthese'] is Map
            ? Map<String, dynamic>.from(m['synthese'] as Map)
            : const {},
      ),
      parc: m['parc'] is Map
          ? AnalyticsParcKpi.fromJson(
              Map<String, dynamic>.from(m['parc'] as Map),
            )
          : null,
      interventions: AnalyticsInterventionsKpi.fromJson(
        m['interventions'] is Map
            ? Map<String, dynamic>.from(m['interventions'] as Map)
            : const {},
      ),
      stock: AnalyticsStockKpi.fromJson(
        m['stock'] is Map
            ? Map<String, dynamic>.from(m['stock'] as Map)
            : const {},
      ),
      comptabilite: AnalyticsComptabiliteKpi.fromJson(
        m['comptabilite'] is Map
            ? Map<String, dynamic>.from(m['comptabilite'] as Map)
            : const {},
      ),
      recouvrement: AnalyticsRecouvrementKpi.fromJson(
        m['recouvrement'] is Map
            ? Map<String, dynamic>.from(m['recouvrement'] as Map)
            : const {},
      ),
      facturation: AnalyticsFacturationKpi.fromJson(
        m['facturation'] is Map
            ? Map<String, dynamic>.from(m['facturation'] as Map)
            : const {},
      ),
      commercial: AnalyticsCommercialKpi.fromJson(
        m['commercial'] is Map
            ? Map<String, dynamic>.from(m['commercial'] as Map)
            : const {},
      ),
      taches: AnalyticsTachesKpi.fromJson(
        m['taches'] is Map
            ? Map<String, dynamic>.from(m['taches'] as Map)
            : const {},
      ),
    );
  }
}

class AnalyticsSynthese {
  AnalyticsSynthese({required this.highlights, required this.zones});

  final List<AnalyticsHighlight> highlights;
  final List<AnalyticsZone> zones;

  factory AnalyticsSynthese.fromJson(Map<String, dynamic> m) {
    final hRaw = m['highlights'];
    final highlights = <AnalyticsHighlight>[];
    if (hRaw is List) {
      for (final e in hRaw) {
        if (e is Map) {
          highlights.add(
            AnalyticsHighlight.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final zRaw = m['zones'];
    final zones = <AnalyticsZone>[];
    if (zRaw is List) {
      for (final e in zRaw) {
        if (e is Map) {
          zones.add(AnalyticsZone.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return AnalyticsSynthese(highlights: highlights, zones: zones);
  }
}

class AnalyticsHighlight {
  AnalyticsHighlight({required this.label, required this.value, this.sublabel});

  final String label;
  final String value;
  final String? sublabel;

  factory AnalyticsHighlight.fromJson(Map<String, dynamic> m) {
    return AnalyticsHighlight(
      label: '${m['label'] ?? ''}',
      value: '${m['value'] ?? ''}',
      sublabel: m['sublabel'] is String ? m['sublabel'] as String : null,
    );
  }
}

class AnalyticsZone {
  AnalyticsZone({
    required this.id,
    required this.title,
    required this.status,
    required this.metrics,
  });

  final String id;
  final String title;
  final String status;
  final List<AnalyticsZoneMetric> metrics;

  factory AnalyticsZone.fromJson(Map<String, dynamic> m) {
    final raw = m['metrics'];
    final metrics = <AnalyticsZoneMetric>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          metrics.add(
            AnalyticsZoneMetric.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return AnalyticsZone(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      status: '${m['status'] ?? 'ok'}',
      metrics: metrics,
    );
  }
}

class AnalyticsZoneMetric {
  AnalyticsZoneMetric({required this.label, required this.value});

  final String label;
  final String value;

  factory AnalyticsZoneMetric.fromJson(Map<String, dynamic> m) {
    return AnalyticsZoneMetric(
      label: '${m['label'] ?? ''}',
      value: '${m['value'] ?? ''}',
    );
  }
}

class AnalyticsParcKpi {
  AnalyticsParcKpi({
    required this.clientsActifs,
    required this.nbSites,
    required this.nbDiffuseurs,
  });

  final int clientsActifs;
  final int nbSites;
  final int nbDiffuseurs;

  factory AnalyticsParcKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsParcKpi(
      clientsActifs: (m['clients_actifs'] as num?)?.toInt() ?? 0,
      nbSites: (m['nb_sites'] as num?)?.toInt() ?? 0,
      nbDiffuseurs: (m['nb_diffuseurs'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsInterventionsKpi {
  AnalyticsInterventionsKpi({
    required this.total,
    required this.periode,
    required this.tauxCloturePct,
    required this.delaiMoyenJours,
    this.reparationsOuvertes = 0,
    this.refill1 = 0,
    this.refill2 = 0,
    this.parType = const [],
    this.parEtat = const [],
    this.tendanceMensuelle = const [],
  });

  final int total;
  final int periode;
  final double tauxCloturePct;
  final double delaiMoyenJours;
  final int reparationsOuvertes;
  final int refill1;
  final int refill2;
  final List<KpiSeriesPoint> parType;
  final List<KpiSeriesPoint> parEtat;
  final List<KpiTrendPoint> tendanceMensuelle;

  factory AnalyticsInterventionsKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsInterventionsKpi(
      total: (m['total'] as num?)?.toInt() ?? 0,
      periode: (m['periode'] as num?)?.toInt() ?? 0,
      tauxCloturePct: (m['taux_cloture_pct'] as num?)?.toDouble() ?? 0,
      delaiMoyenJours: (m['delai_moyen_jours'] as num?)?.toDouble() ?? 0,
      reparationsOuvertes: (m['reparations_ouvertes'] as num?)?.toInt() ?? 0,
      refill1: (m['refill_1'] as num?)?.toInt() ?? 0,
      refill2: (m['refill_2'] as num?)?.toInt() ?? 0,
      parType: KpiSeriesPoint.listFrom(m['par_type']),
      parEtat: KpiSeriesPoint.listFrom(m['par_etat']),
      tendanceMensuelle: KpiTrendPoint.listFrom(m['tendance_mensuelle']),
    );
  }
}

class AnalyticsStockKpi {
  AnalyticsStockKpi({
    required this.sortiesHuileMl,
    required this.alertesConso,
    required this.bonsCommandeOuverts,
    this.valeurStockFcfa = 0,
    this.parEntrepot = const [],
    this.tendanceSorties = const [],
  });

  final double sortiesHuileMl;
  final int alertesConso;
  final int bonsCommandeOuverts;
  final double valeurStockFcfa;
  final List<KpiSeriesPoint> parEntrepot;
  final List<KpiTrendPoint> tendanceSorties;

  factory AnalyticsStockKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsStockKpi(
      sortiesHuileMl: (m['sorties_huile_ml'] as num?)?.toDouble() ??
          (m['sorties_huile_litres'] as num?)?.toDouble() ??
          0,
      alertesConso: (m['alertes_conso'] as num?)?.toInt() ?? 0,
      bonsCommandeOuverts: (m['bons_commande_ouverts'] as num?)?.toInt() ?? 0,
      valeurStockFcfa: (m['valeur_stock_fcfa'] as num?)?.toDouble() ?? 0,
      parEntrepot: KpiSeriesPoint.listFrom(m['par_entrepot']),
      tendanceSorties: KpiTrendPoint.listFrom(m['tendance_sorties']),
    );
  }
}

class AnalyticsComptabiliteKpi {
  AnalyticsComptabiliteKpi({
    required this.operationsPeriode,
    required this.montantTotalFcfa,
    this.demandesMontant,
    this.caCredits,
    this.chargesDebits = 0,
    this.margePct = 0,
    this.ecrituresValideesPct = 0,
    this.parSite = const [],
    this.tendanceCa = const [],
  });

  final int operationsPeriode;
  final double montantTotalFcfa;
  final double? demandesMontant;
  final double? caCredits;
  final double chargesDebits;
  final double margePct;
  final double ecrituresValideesPct;
  final List<KpiSeriesPoint> parSite;
  final List<KpiTrendPoint> tendanceCa;

  factory AnalyticsComptabiliteKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsComptabiliteKpi(
      operationsPeriode: (m['operations_periode'] as num?)?.toInt() ?? 0,
      montantTotalFcfa: (m['montant_total_fcfa'] as num?)?.toDouble() ??
          (m['ca_credits'] as num?)?.toDouble() ??
          0,
      demandesMontant: (m['demandes_montant'] as num?)?.toDouble(),
      caCredits: (m['ca_credits'] as num?)?.toDouble(),
      chargesDebits: (m['charges_debits'] as num?)?.toDouble() ?? 0,
      margePct: (m['marge_pct'] as num?)?.toDouble() ?? 0,
      ecrituresValideesPct:
          (m['ecritures_validees_pct'] as num?)?.toDouble() ?? 0,
      parSite: KpiSeriesPoint.listFrom(m['par_site']),
      tendanceCa: KpiTrendPoint.listFrom(m['tendance_ca']),
    );
  }
}

class AnalyticsRecouvrementKpi {
  AnalyticsRecouvrementKpi({
    required this.montantEncours,
    required this.montantRetard,
    required this.montantAttendu,
    required this.nbFacturesRetard,
    required this.nbFacturesAttendu,
    required this.nbRelancesTotal,
    required this.tauxRecouvrementPct,
    this.joursRetardMoyen = 0,
    this.parTrancheRetard = const [],
    this.topFacturesRetard = const [],
  });

  final double montantEncours;
  final double montantRetard;
  final double montantAttendu;
  final int nbFacturesRetard;
  final int nbFacturesAttendu;
  final int nbRelancesTotal;
  final double tauxRecouvrementPct;
  final double joursRetardMoyen;
  final List<KpiSeriesPoint> parTrancheRetard;
  final List<KpiSeriesPoint> topFacturesRetard;

  factory AnalyticsRecouvrementKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsRecouvrementKpi(
      montantEncours: (m['montant_encours'] as num?)?.toDouble() ??
          (m['encours_total_fcfa'] as num?)?.toDouble() ??
          0,
      montantRetard: (m['montant_retard'] as num?)?.toDouble() ?? 0,
      montantAttendu: (m['montant_attendu'] as num?)?.toDouble() ?? 0,
      nbFacturesRetard: (m['nb_factures_retard'] as num?)?.toInt() ?? 0,
      nbFacturesAttendu: (m['nb_factures_attendu'] as num?)?.toInt() ?? 0,
      nbRelancesTotal: (m['nb_relances_total'] as num?)?.toInt() ?? 0,
      tauxRecouvrementPct:
          (m['taux_recouvrement_pct'] as num?)?.toDouble() ?? 0,
      joursRetardMoyen: (m['jours_retard_moyen'] as num?)?.toDouble() ?? 0,
      parTrancheRetard: KpiSeriesPoint.listFrom(m['par_tranche_retard']),
      topFacturesRetard: KpiSeriesPoint.listFrom(m['top_factures_retard']),
    );
  }
}

class AnalyticsFacturationKpi {
  AnalyticsFacturationKpi({
    required this.facturesPeriode,
    required this.montantFactureFcfa,
    this.caFacture = 0,
    this.detteTotale = 0,
    this.facturesRetard = 0,
    this.tauxRecouvrementPct = 0,
    this.parStatut = const [],
    this.tendanceCa = const [],
  });

  final int facturesPeriode;
  final double montantFactureFcfa;
  final double caFacture;
  final double detteTotale;
  final int facturesRetard;
  final double tauxRecouvrementPct;
  final List<KpiSeriesPoint> parStatut;
  final List<KpiTrendPoint> tendanceCa;

  factory AnalyticsFacturationKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsFacturationKpi(
      facturesPeriode: (m['factures_periode'] as num?)?.toInt() ?? 0,
      montantFactureFcfa: (m['montant_facture_fcfa'] as num?)?.toDouble() ??
          (m['ca_facture'] as num?)?.toDouble() ??
          0,
      caFacture: (m['ca_facture'] as num?)?.toDouble() ?? 0,
      detteTotale: (m['dette_totale'] as num?)?.toDouble() ?? 0,
      facturesRetard: (m['factures_retard'] as num?)?.toInt() ?? 0,
      tauxRecouvrementPct:
          (m['taux_recouvrement_pct'] as num?)?.toDouble() ?? 0,
      parStatut: KpiSeriesPoint.listFrom(m['par_statut']),
      tendanceCa: KpiTrendPoint.listFrom(m['tendance_ca']),
    );
  }
}

class AnalyticsCommercialKpi {
  AnalyticsCommercialKpi({
    required this.ventesPeriodeFcfa,
    required this.nbClientsActifs,
  });

  final double ventesPeriodeFcfa;
  final int nbClientsActifs;

  factory AnalyticsCommercialKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsCommercialKpi(
      ventesPeriodeFcfa: (m['ventes_periode_fcfa'] as num?)?.toDouble() ?? 0,
      nbClientsActifs: (m['nb_clients_actifs'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsTachesKpi {
  AnalyticsTachesKpi({
    required this.totalPeriode,
    required this.termineesPeriode,
    required this.tauxCompletionPct,
    this.enRetard = 0,
    this.observations = 0,
  });

  final int totalPeriode;
  final int termineesPeriode;
  final double tauxCompletionPct;
  final int enRetard;
  final int observations;

  factory AnalyticsTachesKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsTachesKpi(
      totalPeriode: (m['total_periode'] as num?)?.toInt() ?? 0,
      termineesPeriode: (m['terminees_periode'] as num?)?.toInt() ?? 0,
      tauxCompletionPct: (m['taux_completion_pct'] as num?)?.toDouble() ?? 0,
      enRetard: (m['en_retard'] as num?)?.toInt() ?? 0,
      observations: (m['observations'] as num?)?.toInt() ?? 0,
    );
  }
}
