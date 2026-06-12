class RhDashboardMois {
  RhDashboardMois({
    required this.moisAnnee,
    required this.moisLabelFr,
    required this.retardOccurrences,
    required this.absenceCount,
    required this.absencePointage,
    required this.absenceSamedi,
    required this.vacancesJours,
    required this.demandesExplication,
    this.avanceSalaire,
    this.retenuCompta,
    required this.facturesNonConformes,
    required this.ventesBoutiqueMoisTotal,
    required this.boutiqueSeuilAtteint,
    this.remuneration5pctBoutiqueIndividuelle,
    required this.nombreEmployesRepartition,
    required this.nombreAvertissements,
    this.commission5pctVenteDirecte,
    this.primeRentabilite,
  });

  final String moisAnnee;
  final String moisLabelFr;
  final int retardOccurrences;
  final int absenceCount;
  final int absencePointage;
  final int absenceSamedi;
  final int vacancesJours;
  final int demandesExplication;
  final double? avanceSalaire;
  final double? retenuCompta;
  final int facturesNonConformes;
  final double ventesBoutiqueMoisTotal;
  final bool boutiqueSeuilAtteint;
  final double? remuneration5pctBoutiqueIndividuelle;
  final int nombreEmployesRepartition;
  final int nombreAvertissements;
  final double? commission5pctVenteDirecte;
  final double? primeRentabilite;

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory RhDashboardMois.fromJson(Map<String, dynamic> m) {
    return RhDashboardMois(
      moisAnnee: '${m['mois_annee'] ?? ''}',
      moisLabelFr: '${m['mois_label_fr'] ?? ''}',
      retardOccurrences: (m['retard_occurrences'] as num?)?.toInt() ?? 0,
      absenceCount: (m['absence_count'] as num?)?.toInt() ?? 0,
      absencePointage: (m['absence_pointage'] as num?)?.toInt() ?? 0,
      absenceSamedi: (m['absence_samedi'] as num?)?.toInt() ?? 0,
      vacancesJours: (m['vacances_jours'] as num?)?.toInt() ?? 0,
      demandesExplication: (m['demandes_explication'] as num?)?.toInt() ?? 0,
      avanceSalaire: _num(m['avance_salaire']),
      retenuCompta: _num(m['retenu_compta']),
      facturesNonConformes: (m['factures_non_conformes'] as num?)?.toInt() ?? 0,
      ventesBoutiqueMoisTotal: _num(m['ventes_boutique_mois_total']) ?? 0,
      boutiqueSeuilAtteint: m['boutique_seuil_atteint'] == true,
      remuneration5pctBoutiqueIndividuelle:
          _num(m['remuneration_5pct_boutique_individuelle']),
      nombreEmployesRepartition:
          (m['nombre_employes_repartition'] as num?)?.toInt() ?? 0,
      nombreAvertissements: (m['nombre_avertissements'] as num?)?.toInt() ?? 0,
      commission5pctVenteDirecte: _num(m['commission_5pct_vente_directe']),
      primeRentabilite: _num(m['prime_rentabilite']),
    );
  }
}

class RhHistoriqueArrivee {
  RhHistoriqueArrivee({
    this.dateReferenceLabel,
    required this.sansDateEntree,
    required this.absences,
    required this.demandesExplication,
    required this.avertissements,
    this.primeTotale,
    required this.joursCongeTotal,
  });

  final String? dateReferenceLabel;
  final bool sansDateEntree;
  final int absences;
  final int demandesExplication;
  final int avertissements;
  final double? primeTotale;
  final int joursCongeTotal;

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory RhHistoriqueArrivee.fromJson(Map<String, dynamic> m) {
    return RhHistoriqueArrivee(
      dateReferenceLabel: m['date_reference_label'] is String
          ? m['date_reference_label'] as String
          : null,
      sansDateEntree: m['sans_date_entree'] == true,
      absences: (m['absences'] as num?)?.toInt() ?? 0,
      demandesExplication: (m['demandes_explication'] as num?)?.toInt() ?? 0,
      avertissements: (m['avertissements'] as num?)?.toInt() ?? 0,
      primeTotale: _num(m['prime_totale']),
      joursCongeTotal: (m['jours_conge_total'] as num?)?.toInt() ?? 0,
    );
  }
}
