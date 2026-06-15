class KpiSeriesPoint {
  KpiSeriesPoint({required this.label, required this.value});

  final String label;
  final double value;

  static double numVal(dynamic v) {
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
            value: numVal(e['value']),
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
            value: KpiSeriesPoint.numVal(e['value']),
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
    this.relationClient,
    this.controle,
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
  final AnalyticsRelationClientKpi? relationClient;
  final AnalyticsControleKpi? controle;

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
      relationClient: m['relation_client'] is Map
          ? AnalyticsRelationClientKpi.fromJson(
              Map<String, dynamic>.from(m['relation_client'] as Map),
            )
          : null,
      controle: m['controle'] is Map
          ? AnalyticsControleKpi.fromJson(
              Map<String, dynamic>.from(m['controle'] as Map),
            )
          : null,
    );
  }
}

class AnalyticsSynthese {
  AnalyticsSynthese({required this.highlights, required this.zones});

  final List<AnalyticsHighlight> highlights;
  final List<AnalyticsZone> zones;

  factory AnalyticsSynthese.fromJson(Map<String, dynamic> m) {
    final highlights = <AnalyticsHighlight>[];
    if (m['highlights'] is List) {
      for (final e in m['highlights'] as List) {
        if (e is Map) {
          highlights.add(
            AnalyticsHighlight.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final zones = <AnalyticsZone>[];
    if (m['zones'] is List) {
      for (final e in m['zones'] as List) {
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
    this.subtitle,
  });

  final String id;
  final String title;
  final String status;
  final String? subtitle;
  final List<AnalyticsZoneMetric> metrics;

  factory AnalyticsZone.fromJson(Map<String, dynamic> m) {
    final metrics = <AnalyticsZoneMetric>[];
    if (m['metrics'] is List) {
      for (final e in m['metrics'] as List) {
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
      subtitle: m['subtitle'] is String ? m['subtitle'] as String : null,
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

class AnalyticsRelationClientKpi {
  AnalyticsRelationClientKpi({
    required this.clientsInteractionsFaibles,
    required this.rapportsEnvoyes,
    required this.rapportsManquants,
    required this.tauxRapportPct,
  });

  final int clientsInteractionsFaibles;
  final int rapportsEnvoyes;
  final int rapportsManquants;
  final double tauxRapportPct;

  factory AnalyticsRelationClientKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsRelationClientKpi(
      clientsInteractionsFaibles:
          (m['clients_interactions_faibles'] as num?)?.toInt() ?? 0,
      rapportsEnvoyes: (m['rapports_envoyes'] as num?)?.toInt() ?? 0,
      rapportsManquants: (m['rapports_manquants'] as num?)?.toInt() ?? 0,
      tauxRapportPct: (m['taux_rapport_pct'] as num?)?.toDouble() ?? 0,
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
    this.adcRealises = 0,
    this.vdcTotal = 0,
    this.mesuresPeriode,
    this.mesuresEnRetard,
    this.reparationsPeriode,
    this.reparationsDelaiMoyenJours,
    this.tauxAdcVdcPct,
    this.parType = const [],
    this.parEtat = const [],
    this.parTechnicien = const [],
    this.parSite = const [],
    this.adcParStatut = const [],
    this.adcParRessenti = const [],
    this.reparationsParStatut = const [],
    this.reparationsParPanne = const [],
    this.tendanceMensuelle = const [],
    this.rapportTechnicien,
  });

  final int total;
  final int periode;
  final double tauxCloturePct;
  final double delaiMoyenJours;
  final int reparationsOuvertes;
  final int refill1;
  final int refill2;
  final int adcRealises;
  final int vdcTotal;
  final int? mesuresPeriode;
  final int? mesuresEnRetard;
  final int? reparationsPeriode;
  final double? reparationsDelaiMoyenJours;
  final double? tauxAdcVdcPct;
  final List<KpiSeriesPoint> parType;
  final List<KpiSeriesPoint> parEtat;
  final List<KpiSeriesPoint> parTechnicien;
  final List<KpiSeriesPoint> parSite;
  final List<KpiSeriesPoint> adcParStatut;
  final List<KpiSeriesPoint> adcParRessenti;
  final List<KpiSeriesPoint> reparationsParStatut;
  final List<KpiSeriesPoint> reparationsParPanne;
  final List<KpiTrendPoint> tendanceMensuelle;
  final AnalyticsRapportTechnicienKpi? rapportTechnicien;

  factory AnalyticsInterventionsKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsInterventionsKpi(
      total: (m['total'] as num?)?.toInt() ?? 0,
      periode: (m['periode'] as num?)?.toInt() ?? 0,
      tauxCloturePct: (m['taux_cloture_pct'] as num?)?.toDouble() ?? 0,
      delaiMoyenJours: (m['delai_moyen_jours'] as num?)?.toDouble() ?? 0,
      reparationsOuvertes: (m['reparations_ouvertes'] as num?)?.toInt() ?? 0,
      refill1: (m['refill_1'] as num?)?.toInt() ?? 0,
      refill2: (m['refill_2'] as num?)?.toInt() ?? 0,
      adcRealises: (m['adc_realises'] as num?)?.toInt() ?? 0,
      vdcTotal: (m['vdc_total'] as num?)?.toInt() ?? 0,
      mesuresPeriode: (m['mesures_periode'] as num?)?.toInt(),
      mesuresEnRetard: (m['mesures_en_retard'] as num?)?.toInt(),
      reparationsPeriode: (m['reparations_periode'] as num?)?.toInt(),
      reparationsDelaiMoyenJours:
          (m['reparations_delai_moyen_jours'] as num?)?.toDouble(),
      tauxAdcVdcPct: (m['taux_adc_vdc_pct'] as num?)?.toDouble(),
      parType: KpiSeriesPoint.listFrom(m['par_type']),
      parEtat: KpiSeriesPoint.listFrom(m['par_etat']),
      parTechnicien: KpiSeriesPoint.listFrom(m['par_technicien']),
      parSite: KpiSeriesPoint.listFrom(m['par_site']),
      adcParStatut: KpiSeriesPoint.listFrom(m['adc_par_statut']),
      adcParRessenti: KpiSeriesPoint.listFrom(m['adc_par_ressenti']),
      reparationsParStatut: KpiSeriesPoint.listFrom(m['reparations_par_statut']),
      reparationsParPanne: KpiSeriesPoint.listFrom(m['reparations_par_panne']),
      tendanceMensuelle: KpiTrendPoint.listFrom(m['tendance_mensuelle']),
      rapportTechnicien: m['rapport_technicien'] is Map
          ? AnalyticsRapportTechnicienKpi.fromJson(
              Map<String, dynamic>.from(m['rapport_technicien'] as Map),
            )
          : null,
    );
  }
}

class AnalyticsRapportTechnicienKpi {
  AnalyticsRapportTechnicienKpi({
    required this.evaluationsRealisees,
    required this.rapportsDisponibles,
    required this.evaluationsEnAttente,
    required this.scoreMoyenPct,
    this.parTechnicien = const [],
    this.evaluations = const [],
    this.peseeUtiliseeTotalG,
    this.stockSortieHuileTotal,
    this.ecartUtilisationMoyenG,
  });

  final int evaluationsRealisees;
  final int rapportsDisponibles;
  final int evaluationsEnAttente;
  final double scoreMoyenPct;
  final List<KpiSeriesPoint> parTechnicien;
  final List<AnalyticsRapportTechnicienRow> evaluations;
  final double? peseeUtiliseeTotalG;
  final double? stockSortieHuileTotal;
  final double? ecartUtilisationMoyenG;

  factory AnalyticsRapportTechnicienKpi.fromJson(Map<String, dynamic> m) {
    final evals = <AnalyticsRapportTechnicienRow>[];
    if (m['evaluations'] is List) {
      for (final e in m['evaluations'] as List) {
        if (e is Map) {
          evals.add(
            AnalyticsRapportTechnicienRow.fromJson(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
    }
    return AnalyticsRapportTechnicienKpi(
      evaluationsRealisees:
          (m['evaluations_realisees'] as num?)?.toInt() ?? 0,
      rapportsDisponibles: (m['rapports_disponibles'] as num?)?.toInt() ?? 0,
      evaluationsEnAttente:
          (m['evaluations_en_attente'] as num?)?.toInt() ?? 0,
      scoreMoyenPct: (m['score_moyen_pct'] as num?)?.toDouble() ?? 0,
      parTechnicien: KpiSeriesPoint.listFrom(m['par_technicien']),
      evaluations: evals,
      peseeUtiliseeTotalG: (m['pesee_utilisee_total_g'] as num?)?.toDouble(),
      stockSortieHuileTotal:
          (m['stock_sortie_huile_total'] as num?)?.toDouble(),
      ecartUtilisationMoyenG:
          (m['ecart_utilisation_moyen_g'] as num?)?.toDouble(),
    );
  }
}

class AnalyticsRapportTechnicienRow {
  AnalyticsRapportTechnicienRow({
    required this.interventionId,
    required this.dateLabel,
    required this.technicien,
    required this.typeIntervention,
    required this.client,
    required this.ref,
    required this.points,
    required this.maxPoints,
    required this.scorePct,
  });

  final String interventionId;
  final String dateLabel;
  final String technicien;
  final String typeIntervention;
  final String client;
  final String ref;
  final int points;
  final int maxPoints;
  final double scorePct;

  factory AnalyticsRapportTechnicienRow.fromJson(Map<String, dynamic> m) {
    return AnalyticsRapportTechnicienRow(
      interventionId: '${m['intervention_id'] ?? ''}',
      dateLabel: '${m['date_label'] ?? ''}',
      technicien: '${m['technicien'] ?? ''}',
      typeIntervention: '${m['type_intervention'] ?? ''}',
      client: '${m['client'] ?? ''}',
      ref: '${m['ref'] ?? ''}',
      points: (m['points'] as num?)?.toInt() ?? 0,
      maxPoints: (m['max_points'] as num?)?.toInt() ?? 0,
      scorePct: (m['score_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalyticsStockKpi {
  AnalyticsStockKpi({
    required this.sortiesHuileMl,
    required this.alertesConso,
    required this.bonsCommandeOuverts,
    this.retoursMl = 0,
    this.valeurStockFcfa = 0,
    this.bcFournisseurOuverts,
    this.sortiesEnAttente,
    this.rupturesEntrepot = 0,
    this.rotationJours = 0,
    this.refillEcartMoyenJours,
    this.consoEcartPct,
    this.productionLots,
    this.productionVolumeMl,
    this.productionProduitsCount,
    this.parEntrepot = const [],
    this.bcFournisseurParStatut = const [],
    this.consoParClientTop = const [],
    this.topMateriauxSortie = const [],
    this.topClientsTransport = const [],
    this.productionParStatut = const [],
    this.productionTopProduits = const [],
    this.tendanceSorties = const [],
  });

  final double sortiesHuileMl;
  final double retoursMl;
  final int alertesConso;
  final int bonsCommandeOuverts;
  final int? bcFournisseurOuverts;
  final int? sortiesEnAttente;
  final double valeurStockFcfa;
  final int rupturesEntrepot;
  final double rotationJours;
  final double? refillEcartMoyenJours;
  final double? consoEcartPct;
  final int? productionLots;
  final double? productionVolumeMl;
  final int? productionProduitsCount;
  final List<KpiSeriesPoint> parEntrepot;
  final List<KpiSeriesPoint> bcFournisseurParStatut;
  final List<KpiSeriesPoint> consoParClientTop;
  final List<KpiSeriesPoint> topMateriauxSortie;
  final List<KpiSeriesPoint> topClientsTransport;
  final List<KpiSeriesPoint> productionParStatut;
  final List<KpiSeriesPoint> productionTopProduits;
  final List<KpiTrendPoint> tendanceSorties;

  factory AnalyticsStockKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsStockKpi(
      sortiesHuileMl: (m['sorties_huile_ml'] as num?)?.toDouble() ??
          (m['sorties_huile_litres'] as num?)?.toDouble() ??
          0,
      retoursMl: (m['retours_ml'] as num?)?.toDouble() ??
          (m['retours_litres'] as num?)?.toDouble() ??
          0,
      alertesConso: (m['alertes_conso'] as num?)?.toInt() ?? 0,
      bonsCommandeOuverts: (m['bons_commande_ouverts'] as num?)?.toInt() ?? 0,
      bcFournisseurOuverts: (m['bc_fournisseur_ouverts'] as num?)?.toInt(),
      sortiesEnAttente: (m['sorties_en_attente'] as num?)?.toInt(),
      valeurStockFcfa: (m['valeur_stock_fcfa'] as num?)?.toDouble() ?? 0,
      rupturesEntrepot: (m['ruptures_entrepot'] as num?)?.toInt() ?? 0,
      rotationJours: (m['rotation_jours'] as num?)?.toDouble() ?? 0,
      refillEcartMoyenJours:
          (m['refill_ecart_moyen_jours'] as num?)?.toDouble(),
      consoEcartPct: (m['conso_ecart_pct'] as num?)?.toDouble(),
      productionLots: (m['production_lots'] as num?)?.toInt(),
      productionVolumeMl: (m['production_volume_ml'] as num?)?.toDouble(),
      productionProduitsCount:
          (m['production_produits_count'] as num?)?.toInt(),
      parEntrepot: KpiSeriesPoint.listFrom(m['par_entrepot']),
      bcFournisseurParStatut:
          KpiSeriesPoint.listFrom(m['bc_fournisseur_par_statut']),
      consoParClientTop: KpiSeriesPoint.listFrom(m['conso_par_client_top']),
      topMateriauxSortie: KpiSeriesPoint.listFrom(m['top_materiaux_sortie']),
      topClientsTransport: KpiSeriesPoint.listFrom(m['top_clients_transport']),
      productionParStatut: KpiSeriesPoint.listFrom(m['production_par_statut']),
      productionTopProduits:
          KpiSeriesPoint.listFrom(m['production_top_produits']),
      tendanceSorties: KpiTrendPoint.listFrom(m['tendance_sorties']),
    );
  }
}

class AnalyticsComptabiliteKpi {
  AnalyticsComptabiliteKpi({
    required this.caCredits,
    required this.chargesDebits,
    required this.margePct,
    required this.ecrituresValideesPct,
    required this.ecartPrevisionnelPct,
    required this.transportTotal,
    this.demandesMontant,
    this.demandesNonPayees,
    this.montantContratTtc,
    this.jourDepotFacture,
    this.parSite = const [],
    this.depensesMensuelles = const [],
    this.resultatMensuel = const [],
    this.parCompte = const [],
    this.demandesParStatut = const [],
    this.tendanceCa = const [],
    this.operationsPeriode = 0,
  });

  final double caCredits;
  final double chargesDebits;
  final double margePct;
  final double ecrituresValideesPct;
  final double ecartPrevisionnelPct;
  final double transportTotal;
  final double? demandesMontant;
  final int? demandesNonPayees;
  final double? montantContratTtc;
  final int? jourDepotFacture;
  final List<KpiSeriesPoint> parSite;
  final List<KpiTrendPoint> depensesMensuelles;
  final List<KpiTrendPoint> resultatMensuel;
  final List<KpiSeriesPoint> parCompte;
  final List<KpiSeriesPoint> demandesParStatut;
  final List<KpiTrendPoint> tendanceCa;
  final int operationsPeriode;

  double get montantTotalFcfa => caCredits;

  factory AnalyticsComptabiliteKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsComptabiliteKpi(
      caCredits: (m['ca_credits'] as num?)?.toDouble() ??
          (m['montant_total_fcfa'] as num?)?.toDouble() ??
          0,
      chargesDebits: (m['charges_debits'] as num?)?.toDouble() ?? 0,
      margePct: (m['marge_pct'] as num?)?.toDouble() ?? 0,
      ecrituresValideesPct:
          (m['ecritures_validees_pct'] as num?)?.toDouble() ?? 0,
      ecartPrevisionnelPct:
          (m['ecart_previsionnel_pct'] as num?)?.toDouble() ?? 0,
      transportTotal: (m['transport_total'] as num?)?.toDouble() ?? 0,
      demandesMontant: (m['demandes_montant'] as num?)?.toDouble(),
      demandesNonPayees: (m['demandes_non_payees'] as num?)?.toInt(),
      montantContratTtc: (m['montant_contrat_ttc'] as num?)?.toDouble(),
      jourDepotFacture: (m['jour_depot_facture'] as num?)?.toInt(),
      parSite: KpiSeriesPoint.listFrom(m['par_site']),
      depensesMensuelles: KpiTrendPoint.listFrom(m['depenses_mensuelles']),
      resultatMensuel: KpiTrendPoint.listFrom(m['resultat_mensuel']),
      parCompte: KpiSeriesPoint.listFrom(m['par_compte']),
      demandesParStatut: KpiSeriesPoint.listFrom(m['demandes_par_statut']),
      tendanceCa: KpiTrendPoint.listFrom(m['tendance_ca']),
      operationsPeriode: (m['operations_periode'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsRecouvrementKpi {
  AnalyticsRecouvrementKpi({
    required this.montantRetard,
    required this.montantAttendu,
    required this.montantEncours,
    required this.nbFacturesRetard,
    required this.nbFacturesAttendu,
    required this.nbRelancesTotal,
    this.joursRetardMoyen = 0,
    this.joursRetardMax = 0,
    this.nbSansDecharge = 0,
    this.facturesAvecRelance = 0,
    this.facturesSansAssignation = 0,
    this.tauxRecouvrementPct = 0,
    this.parAssigne = const [],
    this.montantParAssigne = const [],
    this.parTrancheRetard = const [],
    this.montantParTrancheRetard = const [],
    this.parNombreRelances = const [],
    this.topFacturesRetard = const [],
  });

  final double montantRetard;
  final double montantAttendu;
  final double montantEncours;
  final int nbFacturesRetard;
  final int nbFacturesAttendu;
  final int nbRelancesTotal;
  final double joursRetardMoyen;
  final double joursRetardMax;
  final int nbSansDecharge;
  final int facturesAvecRelance;
  final int facturesSansAssignation;
  final double tauxRecouvrementPct;
  final List<KpiSeriesPoint> parAssigne;
  final List<KpiSeriesPoint> montantParAssigne;
  final List<KpiSeriesPoint> parTrancheRetard;
  final List<KpiSeriesPoint> montantParTrancheRetard;
  final List<KpiSeriesPoint> parNombreRelances;
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
      joursRetardMoyen: (m['jours_retard_moyen'] as num?)?.toDouble() ?? 0,
      joursRetardMax: (m['jours_retard_max'] as num?)?.toDouble() ?? 0,
      nbSansDecharge: (m['nb_sans_decharge'] as num?)?.toInt() ?? 0,
      facturesAvecRelance:
          (m['factures_avec_relance'] as num?)?.toInt() ?? 0,
      facturesSansAssignation:
          (m['factures_sans_assignation'] as num?)?.toInt() ?? 0,
      tauxRecouvrementPct:
          (m['taux_recouvrement_pct'] as num?)?.toDouble() ?? 0,
      parAssigne: KpiSeriesPoint.listFrom(m['par_assigne']),
      montantParAssigne: KpiSeriesPoint.listFrom(m['montant_par_assigne']),
      parTrancheRetard: KpiSeriesPoint.listFrom(m['par_tranche_retard']),
      montantParTrancheRetard:
          KpiSeriesPoint.listFrom(m['montant_par_tranche_retard']),
      parNombreRelances: KpiSeriesPoint.listFrom(m['par_nombre_relances']),
      topFacturesRetard: KpiSeriesPoint.listFrom(m['top_factures_retard']),
    );
  }
}

class AnalyticsFacturationKpi {
  AnalyticsFacturationKpi({
    required this.caFacture,
    required this.detteTotale,
    required this.facturesRetard,
    required this.tauxRecouvrementPct,
    required this.nbRelances,
    required this.delaiPaiementMoyenJours,
    this.joursRetardMoyen,
    this.delaiEnvoiFactureJours,
    this.caNetPeriode,
    this.tauxSyncDolibarrPct,
    this.parStatut = const [],
    this.parCanalEnvoi = const [],
    this.recouvrementParAssigne = const [],
    this.tendanceCa = const [],
    this.facturesPeriode = 0,
    this.montantFactureFcfa = 0,
  });

  final double caFacture;
  final double detteTotale;
  final int facturesRetard;
  final double tauxRecouvrementPct;
  final int nbRelances;
  final double delaiPaiementMoyenJours;
  final double? joursRetardMoyen;
  final double? delaiEnvoiFactureJours;
  final double? caNetPeriode;
  final double? tauxSyncDolibarrPct;
  final List<KpiSeriesPoint> parStatut;
  final List<KpiSeriesPoint> parCanalEnvoi;
  final List<KpiSeriesPoint> recouvrementParAssigne;
  final List<KpiTrendPoint> tendanceCa;
  final int facturesPeriode;
  final double montantFactureFcfa;

  factory AnalyticsFacturationKpi.fromJson(Map<String, dynamic> m) {
    final ca = (m['ca_facture'] as num?)?.toDouble() ??
        (m['montant_facture_fcfa'] as num?)?.toDouble() ??
        0;
    return AnalyticsFacturationKpi(
      caFacture: ca,
      detteTotale: (m['dette_totale'] as num?)?.toDouble() ?? 0,
      facturesRetard: (m['factures_retard'] as num?)?.toInt() ?? 0,
      tauxRecouvrementPct:
          (m['taux_recouvrement_pct'] as num?)?.toDouble() ?? 0,
      nbRelances: (m['nb_relances'] as num?)?.toInt() ?? 0,
      delaiPaiementMoyenJours:
          (m['delai_paiement_moyen_jours'] as num?)?.toDouble() ?? 0,
      joursRetardMoyen: (m['jours_retard_moyen'] as num?)?.toDouble(),
      delaiEnvoiFactureJours:
          (m['delai_envoi_facture_jours'] as num?)?.toDouble(),
      caNetPeriode: (m['ca_net_periode'] as num?)?.toDouble(),
      tauxSyncDolibarrPct: (m['taux_sync_dolibarr_pct'] as num?)?.toDouble(),
      parStatut: KpiSeriesPoint.listFrom(m['par_statut']),
      parCanalEnvoi: KpiSeriesPoint.listFrom(m['par_canal_envoi']),
      recouvrementParAssigne:
          KpiSeriesPoint.listFrom(m['recouvrement_par_assigne']),
      tendanceCa: KpiTrendPoint.listFrom(m['tendance_ca']),
      facturesPeriode: (m['factures_periode'] as num?)?.toInt() ?? 0,
      montantFactureFcfa: ca,
    );
  }
}

class AnalyticsCommercialKpi {
  AnalyticsCommercialKpi({
    required this.caBoutique,
    required this.nbVentes,
    required this.panierMoyen,
    required this.nbOffres,
    this.montantOffres,
    this.prospectsActifs = 0,
    this.prospectsParStatut = const [],
    this.offresParStatut = const [],
    this.parTemperature = const [],
    this.ventesParModePaiement = const [],
    this.topProduitsBoutique = const [],
    this.ventesParVille = const [],
    this.topClientsAchats = const [],
    this.tendanceVentes = const [],
    this.temperature,
    this.etapeCycle,
  });

  final double caBoutique;
  final int nbVentes;
  final double panierMoyen;
  final int nbOffres;
  final double? montantOffres;
  final int prospectsActifs;
  final List<KpiSeriesPoint> prospectsParStatut;
  final List<KpiSeriesPoint> offresParStatut;
  final List<KpiSeriesPoint> parTemperature;
  final List<KpiSeriesPoint> ventesParModePaiement;
  final List<KpiSeriesPoint> topProduitsBoutique;
  final List<KpiSeriesPoint> ventesParVille;
  final List<KpiSeriesPoint> topClientsAchats;
  final List<KpiTrendPoint> tendanceVentes;
  final String? temperature;
  final String? etapeCycle;

  double get ventesPeriodeFcfa => caBoutique;
  int get nbClientsActifs => prospectsActifs;

  factory AnalyticsCommercialKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsCommercialKpi(
      caBoutique: (m['ca_boutique'] as num?)?.toDouble() ??
          (m['ventes_periode_fcfa'] as num?)?.toDouble() ??
          0,
      nbVentes: (m['nb_ventes'] as num?)?.toInt() ?? 0,
      panierMoyen: (m['panier_moyen'] as num?)?.toDouble() ?? 0,
      nbOffres: (m['nb_offres'] as num?)?.toInt() ?? 0,
      montantOffres: (m['montant_offres'] as num?)?.toDouble(),
      prospectsActifs: (m['prospects_actifs'] as num?)?.toInt() ??
          (m['nb_clients_actifs'] as num?)?.toInt() ??
          0,
      prospectsParStatut: KpiSeriesPoint.listFrom(m['prospects_par_statut']),
      offresParStatut: KpiSeriesPoint.listFrom(m['offres_par_statut']),
      parTemperature: KpiSeriesPoint.listFrom(m['par_temperature']),
      ventesParModePaiement:
          KpiSeriesPoint.listFrom(m['ventes_par_mode_paiement']),
      topProduitsBoutique: KpiSeriesPoint.listFrom(m['top_produits_boutique']),
      ventesParVille: KpiSeriesPoint.listFrom(m['ventes_par_ville']),
      topClientsAchats: KpiSeriesPoint.listFrom(m['top_clients_achats']),
      tendanceVentes: KpiTrendPoint.listFrom(m['tendance_ventes']),
      temperature: m['temperature'] is String ? m['temperature'] as String : null,
      etapeCycle: m['etape_cycle'] is String ? m['etape_cycle'] as String : null,
    );
  }
}

class AnalyticsTachesKpi {
  AnalyticsTachesKpi({
    required this.totalPeriode,
    required this.tachesOuvertes,
    required this.tachesEnRetard,
    required this.pctTerminees,
    required this.observationsPeriode,
    required this.observationsAvecAction,
    this.observationsParSource = const [],
    this.pctDansDelais,
    this.prioriteHauteRetard,
  });

  final int totalPeriode;
  final int tachesOuvertes;
  final int tachesEnRetard;
  final double pctTerminees;
  final int observationsPeriode;
  final int observationsAvecAction;
  final List<KpiSeriesPoint> observationsParSource;
  final double? pctDansDelais;
  final int? prioriteHauteRetard;

  int get termineesPeriode =>
      totalPeriode > 0 ? (totalPeriode * pctTerminees / 100).round() : 0;
  double get tauxCompletionPct => pctTerminees;
  int get enRetard => tachesEnRetard;
  int get observations => observationsPeriode;

  factory AnalyticsTachesKpi.fromJson(Map<String, dynamic> m) {
    return AnalyticsTachesKpi(
      totalPeriode: (m['total_periode'] as num?)?.toInt() ?? 0,
      tachesOuvertes: (m['taches_ouvertes'] as num?)?.toInt() ?? 0,
      tachesEnRetard: (m['taches_en_retard'] as num?)?.toInt() ??
          (m['en_retard'] as num?)?.toInt() ??
          0,
      pctTerminees: (m['pct_terminees'] as num?)?.toDouble() ??
          (m['taux_completion_pct'] as num?)?.toDouble() ??
          0,
      observationsPeriode: (m['observations_periode'] as num?)?.toInt() ??
          (m['observations'] as num?)?.toInt() ??
          0,
      observationsAvecAction:
          (m['observations_avec_action'] as num?)?.toInt() ?? 0,
      observationsParSource:
          KpiSeriesPoint.listFrom(m['observations_par_source']),
      pctDansDelais: (m['pct_dans_delais'] as num?)?.toDouble(),
      prioriteHauteRetard: (m['priorite_haute_retard'] as num?)?.toInt(),
    );
  }
}

class AnalyticsControleKpi {
  AnalyticsControleKpi({
    required this.comptabiliteRecouvrement,
    required this.interventions,
    required this.stockLogistique,
    required this.rh,
  });

  final AnalyticsControleSection comptabiliteRecouvrement;
  final AnalyticsControleSection interventions;
  final AnalyticsControleSection stockLogistique;
  final AnalyticsControleSection rh;

  factory AnalyticsControleKpi.fromJson(Map<String, dynamic> m) {
    AnalyticsControleSection section(String key) {
      if (m[key] is Map) {
        return AnalyticsControleSection.fromJson(
          Map<String, dynamic>.from(m[key] as Map),
        );
      }
      return AnalyticsControleSection(titre: key, metrics: const []);
    }

    return AnalyticsControleKpi(
      comptabiliteRecouvrement: section('comptabilite_recouvrement'),
      interventions: section('interventions'),
      stockLogistique: section('stock_logistique'),
      rh: section('rh'),
    );
  }
}

class AnalyticsControleSection {
  AnalyticsControleSection({
    required this.titre,
    required this.metrics,
    this.parMarque = const [],
  });

  final String titre;
  final List<AnalyticsControleMetric> metrics;
  final List<KpiSeriesPoint> parMarque;

  factory AnalyticsControleSection.fromJson(Map<String, dynamic> m) {
    final metrics = <AnalyticsControleMetric>[];
    if (m['metrics'] is List) {
      for (final e in m['metrics'] as List) {
        if (e is Map) {
          metrics.add(
            AnalyticsControleMetric.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return AnalyticsControleSection(
      titre: '${m['titre'] ?? ''}',
      metrics: metrics,
      parMarque: KpiSeriesPoint.listFrom(m['par_marque']),
    );
  }
}

class AnalyticsControleMetric {
  AnalyticsControleMetric({
    required this.label,
    required this.realise,
    this.cible,
    this.enRetard,
    this.unite,
    this.detail,
  });

  final String label;
  final double realise;
  final double? cible;
  final double? enRetard;
  final String? unite;
  final String? detail;

  factory AnalyticsControleMetric.fromJson(Map<String, dynamic> m) {
    return AnalyticsControleMetric(
      label: '${m['label'] ?? ''}',
      realise: KpiSeriesPoint.numVal(m['realise']),
      cible: m['cible'] != null ? KpiSeriesPoint.numVal(m['cible']) : null,
      enRetard:
          m['en_retard'] != null ? KpiSeriesPoint.numVal(m['en_retard']) : null,
      unite: m['unite'] is String ? m['unite'] as String : null,
      detail: m['detail'] is String ? m['detail'] as String : null,
    );
  }
}
