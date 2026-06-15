import 'demande_a_payer.dart';

class PieceJustificativeCompta {
  PieceJustificativeCompta({
    this.fileName,
    this.mimeType,
    this.id,
    this.webViewLink,
    this.webContentLink,
    this.path,
  });

  final String? fileName;
  final String? mimeType;
  final String? id;
  final String? webViewLink;
  final String? webContentLink;
  final String? path;

  String displayName(int index) {
    final name = (fileName ?? '').trim();
    if (name.isNotEmpty) return name;
    return 'Fichier ${index + 1}';
  }

  String? get documentPath {
    for (final v in [webViewLink, webContentLink, path]) {
      final s = (v ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static PieceJustificativeCompta? tryParse(dynamic e) {
    if (e is! Map) return null;
    final m = Map<String, dynamic>.from(e);
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final path = str(m['path']) ?? str(m['url']);
    final webView = str(m['webViewLink']) ?? str(m['web_view_link']);
    final webContent = str(m['webContentLink']) ?? str(m['web_content_link']);
    if (path == null && webView == null && webContent == null) return null;
    return PieceJustificativeCompta(
      fileName: str(m['fileName']) ?? str(m['file_name']) ?? str(m['name']),
      mimeType: str(m['mimeType']) ?? str(m['mime_type']) ?? str(m['type']),
      id: m['id']?.toString(),
      webViewLink: webView,
      webContentLink: webContent,
      path: path,
    );
  }
}

class TransactionComptable {
  TransactionComptable({
    required this.id,
    this.dateTransaction,
    this.groupe,
    this.sousGroupe,
    this.sousCategorie,
    this.designation,
    this.sousDesignation,
    this.site,
    this.agent,
    this.numeroFacture,
    this.typeFacture,
    this.compte,
    this.compteAffichageCanaux,
    this.demandeAuteur,
    this.credit,
    this.debit,
    this.montantHt,
    this.tva,
    this.typeTva,
    this.montantTtc,
    this.observation,
    this.piecesJustificatives = const [],
    this.retenuALaSource,
    this.dateValidation,
    this.validationOk = false,
    this.validationRejetee = false,
  });

  final String id;
  final String? dateTransaction;
  final String? groupe;
  final String? sousGroupe;
  final String? sousCategorie;
  final String? designation;
  final String? sousDesignation;
  final String? site;
  final String? agent;
  final String? numeroFacture;
  final String? typeFacture;
  final String? compte;
  final String? compteAffichageCanaux;
  final String? demandeAuteur;
  final double? credit;
  final double? debit;
  final double? montantHt;
  final double? tva;
  final String? typeTva;
  final double? montantTtc;
  final String? observation;
  final List<PieceJustificativeCompta> piecesJustificatives;
  final bool? retenuALaSource;
  final String? dateValidation;
  final bool validationOk;
  final bool validationRejetee;

  bool get isDepense => (debit ?? 0) > 0;

  String? get compteAffiche {
    final canaux = (compteAffichageCanaux ?? '').trim();
    if (canaux.isNotEmpty) return canaux;
    final c = (compte ?? '').trim();
    return c.isEmpty ? null : c;
  }

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

  String? get observationAffichee {
    final obs = (observation ?? '').trim();
    if (obs.isEmpty) return null;
    final parts = <String>[];
    for (final part in obs.split('|')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final lower = p.toLowerCase();
      if (lower.startsWith('description:')) continue;
      parts.add(p);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory TransactionComptable.fromJson(Map<String, dynamic> m) {
    final rawPj = m['pieces_justificatives'];
    final pj = <PieceJustificativeCompta>[];
    if (rawPj is List) {
      for (final e in rawPj) {
        final p = PieceJustificativeCompta.tryParse(e);
        if (p != null) pj.add(p);
      }
    }

    return TransactionComptable(
      id: '${m['id']}',
      dateTransaction: _str(m['date_transaction']),
      groupe: _str(m['groupe']),
      sousGroupe: _str(m['sous_groupe']),
      sousCategorie: _str(m['sous_categorie']),
      designation: _str(m['designation']),
      sousDesignation: _str(m['sous_designation']),
      site: _str(m['site']),
      agent: _str(m['agent']),
      numeroFacture: _str(m['numero_facture']),
      typeFacture: _str(m['type_facture']),
      compte: _str(m['compte']),
      compteAffichageCanaux: _str(m['compte_affichage_canaux']),
      demandeAuteur: _str(m['demande_auteur']),
      credit: _num(m['credit']),
      debit: _num(m['debit']),
      montantHt: _num(m['montant_ht']),
      tva: _num(m['tva']),
      typeTva: _str(m['type_tva']),
      montantTtc: _num(m['montant_ttc']),
      observation: _str(m['observation']),
      piecesJustificatives: pj,
      retenuALaSource: m['retenu_a_la_source'] == true ? true : null,
      dateValidation: _str(m['date_validation']),
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
    super.payeAt,
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
      payeAt: base.payeAt,
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
