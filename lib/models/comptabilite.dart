import 'demande_a_payer.dart';

class TransactionComptable {
  TransactionComptable({
    required this.id,
    this.dateTransaction,
    this.designation,
    this.site,
    this.demandeAuteur,
    this.credit,
    this.debit,
    this.observation,
    this.validationOk = false,
    this.validationRejetee = false,
  });

  final String id;
  final String? dateTransaction;
  final String? designation;
  final String? site;
  final String? demandeAuteur;
  final double? credit;
  final double? debit;
  final String? observation;
  final bool validationOk;
  final bool validationRejetee;

  bool get isDepense => (debit ?? 0) > 0;

  String get descriptionAffichee {
    final obs = (observation ?? '').trim();
    if (obs.isNotEmpty) {
      for (final part in obs.split('|')) {
        final p = part.trim();
        if (p.toLowerCase().startsWith('description:')) {
          final v = p.substring('description:'.length).trim();
          if (v.isNotEmpty) return v;
        }
      }
    }
    final des = (designation ?? '').trim();
    return des.isEmpty ? '—' : des;
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory TransactionComptable.fromJson(Map<String, dynamic> m) {
    return TransactionComptable(
      id: '${m['id']}',
      dateTransaction: m['date_transaction'] is String
          ? m['date_transaction'] as String
          : null,
      designation: m['designation'] is String ? m['designation'] as String : null,
      site: m['site'] is String ? m['site'] as String : null,
      demandeAuteur:
          m['demande_auteur'] is String ? m['demande_auteur'] as String : null,
      credit: _num(m['credit']),
      debit: _num(m['debit']),
      observation:
          m['observation'] is String ? m['observation'] as String : null,
      validationOk: m['validation_ok'] == true,
      validationRejetee: m['validation_rejetee'] == true,
    );
  }
}

class FacturationCompta {
  FacturationCompta({
    required this.id,
    required this.clientId,
    required this.mois,
    required this.montantFacture,
    this.dolibarrRef,
    this.dolibarrDateCreation,
    this.dechargeEnvoyeeLe,
    this.clientNom,
  });

  final String id;
  final String clientId;
  final String mois;
  final double montantFacture;
  final String? dolibarrRef;
  final String? dolibarrDateCreation;
  final String? dechargeEnvoyeeLe;
  final String? clientNom;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory FacturationCompta.fromJson(Map<String, dynamic> m) {
    return FacturationCompta(
      id: '${m['id']}',
      clientId: '${m['client_id'] ?? ''}',
      mois: '${m['mois'] ?? ''}',
      montantFacture: _num(m['montant_facture']),
      dolibarrRef:
          m['dolibarr_ref'] is String ? m['dolibarr_ref'] as String : null,
      dolibarrDateCreation: m['dolibarr_date_creation'] is String
          ? m['dolibarr_date_creation'] as String
          : null,
      dechargeEnvoyeeLe: m['decharge_envoyee_le'] is String
          ? m['decharge_envoyee_le'] as String
          : null,
      clientNom: m['dolibarr_tier_nom'] is String
          ? m['dolibarr_tier_nom'] as String
          : null,
    );
  }
}

class PrevisionRecetteCompta {
  PrevisionRecetteCompta({
    required this.id,
    required this.libelle,
    required this.montant,
    required this.datePaiementPrevue,
    this.clientNom,
    this.clientLibelle,
    this.createdByEmail,
    this.dateMarquePaye,
    this.observation,
  });

  final String id;
  final String libelle;
  final double montant;
  final String datePaiementPrevue;
  final String? clientNom;
  final String? clientLibelle;
  final String? createdByEmail;
  final String? dateMarquePaye;
  final String? observation;

  String get clientAffiche {
    final n = clientNom?.trim();
    if (n != null && n.isNotEmpty) return n;
    final l = clientLibelle?.trim();
    if (l != null && l.isNotEmpty) return l;
    return '—';
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory PrevisionRecetteCompta.fromJson(Map<String, dynamic> m) {
    return PrevisionRecetteCompta(
      id: '${m['id']}',
      libelle: '${m['libelle'] ?? ''}',
      montant: _num(m['montant']),
      datePaiementPrevue: '${m['date_paiement_prevue'] ?? ''}',
      clientNom: m['client_nom'] is String ? m['client_nom'] as String : null,
      clientLibelle:
          m['client_libelle'] is String ? m['client_libelle'] as String : null,
      createdByEmail: m['created_by_email'] is String
          ? m['created_by_email'] as String
          : null,
      dateMarquePaye: m['date_marque_paye'] is String
          ? m['date_marque_paye'] as String
          : null,
      observation:
          m['observation'] is String ? m['observation'] as String : null,
    );
  }
}

class CaisseDemandeHistorique extends DemandeAPayer {
  CaisseDemandeHistorique({
    required super.id,
    required super.client,
    required super.raisonBonCommande,
    required super.montantDemande,
    required this.dateJourCaisse,
    super.origine,
    super.auteur,
    super.statut,
    super.dateADecaisser,
    super.montantAttendu,
    super.raisonBonTransport,
    super.justificatifs,
    super.valideParHierarchie,
    super.payePar,
    super.createdAt,
    super.updatedAt,
    super.retour,
    super.montantEspece,
    super.montantMomo,
    super.montantOm,
    super.montantCheque,
    super.attenteRetourCaisse,
  });

  final String dateJourCaisse;

  factory CaisseDemandeHistorique.fromJson(Map<String, dynamic> m) {
    final base = DemandeAPayer.fromJson(m);
    return CaisseDemandeHistorique(
      id: base.id,
      client: base.client,
      raisonBonCommande: base.raisonBonCommande,
      montantDemande: base.montantDemande,
      dateJourCaisse: '${m['date_jour_caisse'] ?? ''}',
      origine: base.origine,
      auteur: base.auteur,
      statut: base.statut,
      dateADecaisser: base.dateADecaisser,
      montantAttendu: base.montantAttendu,
      raisonBonTransport: base.raisonBonTransport,
      justificatifs: base.justificatifs,
      valideParHierarchie: base.valideParHierarchie,
      payePar: base.payePar,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      retour: base.retour,
      montantEspece: base.montantEspece,
      montantMomo: base.montantMomo,
      montantOm: base.montantOm,
      montantCheque: base.montantCheque,
      attenteRetourCaisse: base.attenteRetourCaisse,
    );
  }
}
