import 'materiel_sortie_ligne.dart';
import 'sortie_huile_diffuseur.dart';
import 'sortie_huile_totale.dart';

class Intervention {
  Intervention({
    required this.id,
    this.ref,
    this.sujet,
    this.description,
    this.typeIntervention,
    this.site,
    this.siteNom,
    this.ville,
    this.clientNom,
    this.technicienNom,
    this.idTechnicien,
    this.idClients,
    this.idAgence,
    this.dateIntervention,
    this.etat,
    this.etatApp,
    this.auteur,
    this.isAssignedToMe,
    this.sortieHuileParDiffuseur = const [],
    this.sortieHuileTotale = const [],
    this.sortieHuileMode,
    this.materielSortie = const [],
  });

  final String id;
  final String? ref;
  final String? sujet;
  final String? description;
  final String? typeIntervention;
  final String? site;
  final String? siteNom;
  final String? ville;
  final String? clientNom;
  final String? technicienNom;
  final String? idTechnicien;
  final String? idClients;
  final String? idAgence;
  final String? dateIntervention;
  /// État CRM interne.
  final String? etat;
  /// État affiché app / terrain (`etat_app` API).
  final String? etatApp;
  final String? auteur;
  /// Aligné API ``is_assigned_to_me`` (null si API pas encore déployée).
  final bool? isAssignedToMe;
  final List<SortieHuileDiffuseur> sortieHuileParDiffuseur;
  final List<SortieHuileTotale> sortieHuileTotale;
  /// `total` | `diffuseur` | `contractuel`
  final String? sortieHuileMode;
  final List<MaterielSortieLigne> materielSortie;

  bool get hasSortieStock =>
      materielSortie.isNotEmpty ||
      sortieHuileParDiffuseur.isNotEmpty ||
      sortieHuileTotale.isNotEmpty;

  bool get showHuileParDiffuseur =>
      sortieHuileMode == 'diffuseur' || sortieHuileMode == 'contractuel';

  bool get showHuileTotale => sortieHuileMode == 'total';

  /// Libellé état pour l’UI (repli `etat_app` → `etat`).
  String? get etatAffiche => etat ?? etatApp;

  /// Vue technicien : privilégie `etat_app` renvoyé par le backend.
  String? get etatAfficheTechnicien => etatApp ?? etat;

  String get titreAffiche {
    final s = (sujet ?? '').trim();
    if (s.isNotEmpty) return s;
    final r = (ref ?? '').trim();
    if (r.isNotEmpty) return r;
    return 'Intervention';
  }

  String get siteAffiche {
    final sn = (siteNom ?? '').trim();
    if (sn.isNotEmpty) return sn;
    return (site ?? '').trim();
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static bool? _boolOrNull(dynamic v) {
    if (v == true) return true;
    if (v == false) return false;
    return null;
  }

  factory Intervention.fromJson(Map<String, dynamic> m) {
    return Intervention(
      id: '${m['id']}',
      ref: _str(m['ref']),
      sujet: _str(m['sujet']),
      description: _str(m['description']),
      typeIntervention: _str(m['type_intervention']),
      site: _str(m['site']),
      siteNom: _str(m['site_nom']),
      ville: _str(m['ville']),
      clientNom: _str(m['client_nom']),
      technicienNom: _str(m['technicien_nom']),
      idTechnicien: m['id_technicien']?.toString(),
      idClients: m['id_clients']?.toString(),
      idAgence: m['id_agence']?.toString(),
      dateIntervention: _str(m['date_intervention']),
      etat: _str(m['etat']),
      etatApp: _str(m['etat_app']),
      auteur: _str(m['auteur']),
      isAssignedToMe: _boolOrNull(m['is_assigned_to_me']),
      sortieHuileParDiffuseur: parseSortieHuileParDiffuseur(m['sortie_huile_par_diffuseur']),
      sortieHuileTotale: parseSortieHuileTotale(m['sortie_huile_totale']),
      sortieHuileMode: parseSortieHuileMode(m['sortie_huile_mode']),
      materielSortie: parseMaterielSortie(m['materiel_sortie']),
    );
  }
}

class InterventionsListResult {
  InterventionsListResult({required this.items, required this.total});

  final List<Intervention> items;
  final int total;

  factory InterventionsListResult.fromJson(Map<String, dynamic> m) {
    final raw = m['items'];
    final items = <Intervention>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(Intervention.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return InterventionsListResult(
      items: items,
      total: (m['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

class ExperienceAdc {
  ExperienceAdc({
    required this.id,
    this.clientName,
    this.siteName,
    this.datePlanifiee,
    this.dateAppel,
    this.statut,
    this.ressenti,
    this.commentaire,
    this.interventionRef,
    this.interventionDate,
    this.idContact,
    this.actionsTrace = const [],
  });

  final String id;
  final String? clientName;
  final String? siteName;
  final String? datePlanifiee;
  final String? dateAppel;
  final String? statut;
  final String? ressenti;
  final String? commentaire;
  final String? interventionRef;
  final String? interventionDate;
  final String? idContact;
  final List<AdcActionTrace> actionsTrace;

  String get titreAffiche {
    final c = (clientName ?? '').trim();
    if (c.isNotEmpty) return c;
    return 'Appel de courtoisie';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory ExperienceAdc.fromJson(Map<String, dynamic> m) {
    return ExperienceAdc(
      id: '${m['id']}',
      clientName: _str(m['client_name']),
      siteName: _str(m['site_name']),
      datePlanifiee: _str(m['date_planifiee']),
      dateAppel: _str(m['date_appel']),
      statut: _str(m['statut']),
      ressenti: _str(m['ressenti']),
      commentaire: _str(m['commentaire']),
      interventionRef: _str(m['intervention_ref']),
      interventionDate: _str(m['intervention_date']),
      idContact: m['id_contact']?.toString(),
      actionsTrace: _parseAdcActionTrace(m['actions_trace']),
    );
  }
}

class AdcContact {
  AdcContact({
    required this.id,
    this.nom,
    this.prenom,
    this.poste,
    this.telephone,
    this.email,
    this.typeContact,
  });

  final String id;
  final String? nom;
  final String? prenom;
  final String? poste;
  final String? telephone;
  final String? email;
  final String? typeContact;

  String get nomAffiche {
    final parts = [(prenom ?? '').trim(), (nom ?? '').trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return '—';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory AdcContact.fromJson(Map<String, dynamic> m) {
    return AdcContact(
      id: '${m['id']}',
      nom: _str(m['nom']),
      prenom: _str(m['prenom']),
      poste: _str(m['poste']),
      telephone: _str(m['telephone']),
      email: _str(m['email']),
      typeContact: _str(m['type_contact']),
    );
  }
}

class AdcActionTrace {
  AdcActionTrace({
    this.date,
    this.heure,
    this.canal,
    this.message,
    this.contact,
    this.auteur,
    this.ressenti,
  });

  final String? date;
  final String? heure;
  final String? canal;
  final String? message;
  final String? contact;
  final String? auteur;
  final String? ressenti;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory AdcActionTrace.fromJson(Map<String, dynamic> m) {
    return AdcActionTrace(
      date: _str(m['date']),
      heure: _str(m['heure']),
      canal: _str(m['canal']),
      message: _str(m['message']) ?? _str(m['description']),
      contact: _str(m['contact']),
      auteur: _str(m['auteur']),
      ressenti: _str(m['ressenti']),
    );
  }
}

List<AdcActionTrace> _parseAdcActionTrace(dynamic raw) {
  final trace = <AdcActionTrace>[];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        trace.add(AdcActionTrace.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }
  return trace;
}

class ExperienceAdcDetail extends ExperienceAdc {
  ExperienceAdcDetail({
    required super.id,
    super.clientName,
    super.siteName,
    super.datePlanifiee,
    super.dateAppel,
    super.statut,
    super.ressenti,
    super.commentaire,
    super.interventionRef,
    super.interventionDate,
    super.idContact,
    super.actionsTrace,
    this.clientId,
    this.siteId,
    this.relanceWhatsappMessage,
    this.relanceMailMessage,
    this.relanceTelephoneMessage,
    this.contacts = const [],
  });

  final String? clientId;
  final String? siteId;
  final String? relanceWhatsappMessage;
  final String? relanceMailMessage;
  final String? relanceTelephoneMessage;
  final List<AdcContact> contacts;

  factory ExperienceAdcDetail.fromJson(Map<String, dynamic> m) {
    final base = ExperienceAdc.fromJson(m);
    final rawContacts = m['contacts'];
    final contacts = <AdcContact>[];
    if (rawContacts is List) {
      for (final e in rawContacts) {
        if (e is Map) {
          contacts.add(AdcContact.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final trace = _parseAdcActionTrace(m['actions_trace']);
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;

    return ExperienceAdcDetail(
      id: base.id,
      clientName: base.clientName,
      siteName: base.siteName,
      datePlanifiee: base.datePlanifiee,
      dateAppel: base.dateAppel,
      statut: base.statut,
      ressenti: base.ressenti,
      commentaire: base.commentaire,
      interventionRef: base.interventionRef,
      interventionDate: base.interventionDate,
      idContact: base.idContact,
      clientId: m['client_id']?.toString(),
      siteId: m['site_id']?.toString(),
      relanceWhatsappMessage: str(m['relance_whatsapp_message']),
      relanceMailMessage: str(m['relance_mail_message']),
      relanceTelephoneMessage: str(m['relance_telephone_message']),
      contacts: contacts,
      actionsTrace: trace,
    );
  }
}

class TransportPoint {
  TransportPoint({
    required this.id,
    this.ordre,
    this.lieuDepart,
    this.quartierDepart,
    this.clientNomDepart,
    this.lieuArrivee,
    this.quartierArrivee,
    this.clientNom,
    this.sousDesignation,
    this.montant,
  });

  final String id;
  final int? ordre;
  final String? lieuDepart;
  final String? quartierDepart;
  final String? clientNomDepart;
  final String? lieuArrivee;
  final String? quartierArrivee;
  final String? clientNom;
  final String? sousDesignation;
  final double? montant;

  String get departAffiche {
    final q = (quartierDepart ?? '').trim();
    if (q.isNotEmpty) return q;
    return (lieuDepart ?? '').trim();
  }

  String get arriveeAffiche {
    final q = (quartierArrivee ?? '').trim();
    if (q.isNotEmpty) return q;
    return (lieuArrivee ?? '').trim();
  }

  String get trajetLabel {
    final dep = departAffiche;
    final arr = arriveeAffiche;
    if (dep.isEmpty && arr.isEmpty) return '—';
    return '${dep.isEmpty ? '?' : dep} → ${arr.isEmpty ? '?' : arr}';
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory TransportPoint.fromJson(Map<String, dynamic> m) {
    return TransportPoint(
      id: '${m['id']}',
      ordre: (m['ordre'] as num?)?.toInt(),
      lieuDepart: _str(m['lieu_depart']),
      quartierDepart: _str(m['quartier_depart']),
      clientNomDepart: _str(m['client_nom_depart']),
      lieuArrivee: _str(m['lieu_arrivee']),
      quartierArrivee: _str(m['quartier_arrivee']),
      clientNom: _str(m['client_nom']),
      sousDesignation: _str(m['sous_designation']),
      montant: _num(m['montant']),
    );
  }
}

class TransportIntervention {
  TransportIntervention({
    required this.id,
    this.dateTransport,
    this.ville,
    this.raisonDeplacement,
    this.montantTotal,
    this.technicienNom,
    this.points = const [],
  });

  final String id;
  final String? dateTransport;
  final String? ville;
  final String? raisonDeplacement;
  final double? montantTotal;
  final String? technicienNom;
  final List<TransportPoint> points;

  int get pointsCount => points.length;

  String get titreAffiche {
    final r = (raisonDeplacement ?? '').trim();
    if (r.isNotEmpty) return r;
    final v = (ville ?? '').trim();
    if (v.isNotEmpty) return 'Transport · $v';
    return 'Fiche transport';
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory TransportIntervention.fromJson(Map<String, dynamic> m) {
    final rawPoints = m['points'];
    final points = <TransportPoint>[];
    if (rawPoints is List) {
      for (final e in rawPoints) {
        if (e is Map) {
          points.add(TransportPoint.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    points.sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));

    return TransportIntervention(
      id: '${m['id']}',
      dateTransport: _str(m['date_transport']),
      ville: _str(m['ville']),
      raisonDeplacement: _str(m['raison_deplacement']),
      montantTotal: _num(m['montant_total']),
      technicienNom: _str(m['technicien_nom']),
      points: points,
    );
  }
}

class Reparation {
  Reparation({
    required this.id,
    required this.panne,
    required this.statut,
    this.reference,
    this.descriptionProbleme,
    this.clientNom,
    this.prospectNom,
    this.technicienNom,
    this.typeDiffuseur,
    this.referenceDiffuseur,
  });

  final String id;
  final String? reference;
  final String panne;
  final String? descriptionProbleme;
  final String statut;
  final String? clientNom;
  final String? prospectNom;
  final String? technicienNom;
  final String? typeDiffuseur;
  final String? referenceDiffuseur;

  String get titreAffiche {
    final r = (reference ?? '').trim();
    if (r.isNotEmpty) return r;
    return panne.trim().isNotEmpty ? panne.trim() : 'Réparation';
  }

  String get clientAffiche {
    final c = (clientNom ?? '').trim();
    if (c.isNotEmpty) return c;
    return (prospectNom ?? '').trim().isNotEmpty
        ? prospectNom!.trim()
        : '—';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory Reparation.fromJson(Map<String, dynamic> m) {
    return Reparation(
      id: '${m['id']}',
      reference: _str(m['reference']),
      panne: '${m['panne'] ?? ''}',
      descriptionProbleme: _str(m['description_probleme']),
      statut: '${m['statut'] ?? ''}',
      clientNom: _str(m['client_nom']),
      prospectNom: _str(m['prospect_nom']),
      technicienNom: _str(m['technicien_nom']),
      typeDiffuseur: _str(m['type_diffuseur']),
      referenceDiffuseur: _str(m['reference_diffuseur']),
    );
  }
}

class ReparationsListResult {
  ReparationsListResult({required this.items, required this.total});

  final List<Reparation> items;
  final int total;

  factory ReparationsListResult.fromJson(Map<String, dynamic> m) {
    final raw = m['items'];
    final items = <Reparation>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(Reparation.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return ReparationsListResult(
      items: items,
      total: (m['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

class RapportMensuelClientSummary {
  RapportMensuelClientSummary({
    required this.clientId,
    required this.clientNom,
    required this.nbInterventions,
    required this.nbAdc,
    required this.nbVdc,
    required this.nbPlanning,
    this.sites = const [],
  });

  final String clientId;
  final String clientNom;
  final int nbInterventions;
  final int nbAdc;
  final int nbVdc;
  final int nbPlanning;
  final List<RapportMensuelSiteSummary> sites;

  factory RapportMensuelClientSummary.fromJson(Map<String, dynamic> m) {
    final rawSites = m['sites'];
    final sites = <RapportMensuelSiteSummary>[];
    if (rawSites is List) {
      for (final e in rawSites) {
        if (e is Map) {
          sites.add(
            RapportMensuelSiteSummary.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return RapportMensuelClientSummary(
      clientId: '${m['client_id'] ?? ''}',
      clientNom: '${m['client_nom'] ?? ''}',
      nbInterventions: (m['nb_interventions'] as num?)?.toInt() ?? 0,
      nbAdc: (m['nb_adc'] as num?)?.toInt() ?? 0,
      nbVdc: (m['nb_vdc'] as num?)?.toInt() ?? 0,
      nbPlanning: (m['nb_planning'] as num?)?.toInt() ?? 0,
      sites: sites,
    );
  }
}

class RapportMensuelSiteSummary {
  RapportMensuelSiteSummary({
    required this.site,
    required this.nbInterventions,
    required this.nbAdc,
    required this.nbVdc,
  });

  final String site;
  final int nbInterventions;
  final int nbAdc;
  final int nbVdc;

  factory RapportMensuelSiteSummary.fromJson(Map<String, dynamic> m) {
    return RapportMensuelSiteSummary(
      site: '${m['site'] ?? ''}',
      nbInterventions: (m['nb_interventions'] as num?)?.toInt() ?? 0,
      nbAdc: (m['nb_adc'] as num?)?.toInt() ?? 0,
      nbVdc: (m['nb_vdc'] as num?)?.toInt() ?? 0,
    );
  }
}

class RapportMensuelSummary {
  RapportMensuelSummary({
    required this.mois,
    required this.moisLabel,
    required this.clients,
  });

  final String mois;
  final String moisLabel;
  final List<RapportMensuelClientSummary> clients;

  factory RapportMensuelSummary.fromJson(Map<String, dynamic> m) {
    final raw = m['clients'];
    final clients = <RapportMensuelClientSummary>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          clients.add(
            RapportMensuelClientSummary.fromJson(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
    }
    return RapportMensuelSummary(
      mois: '${m['mois'] ?? ''}',
      moisLabel: '${m['mois_label'] ?? ''}',
      clients: clients,
    );
  }
}

class RapportMensuelLigne {
  RapportMensuelLigne({
    required this.interventionId,
    this.lieu,
    this.dateLabel,
    this.action,
    this.observation,
    this.ressentiClient,
    this.ressentiTechnicien,
    this.nomContact,
  });

  final String interventionId;
  final String? lieu;
  final String? dateLabel;
  final String? action;
  final String? observation;
  final String? ressentiClient;
  final String? ressentiTechnicien;
  final String? nomContact;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory RapportMensuelLigne.fromJson(Map<String, dynamic> m) {
    return RapportMensuelLigne(
      interventionId: '${m['intervention_id'] ?? m['id'] ?? ''}',
      lieu: _str(m['lieu']),
      dateLabel: _str(m['date_label']) ?? _str(m['date_intervention_label']),
      action: _str(m['action']),
      observation: _str(m['observation']),
      ressentiClient: _str(m['ressenti_client']),
      ressentiTechnicien: _str(m['ressenti_technicien']),
      nomContact: _str(m['nom_contact']),
    );
  }
}

class RapportMensuelDetail {
  RapportMensuelDetail({
    required this.clientId,
    required this.clientNom,
    required this.mois,
    required this.moisLabel,
    this.codeClient,
    this.moisSuivantLabel,
    this.sites = const [],
    this.interactionsAdc = const [],
    this.interactionsVdc = const [],
    this.interactionsRefill = const [],
    this.planning = const [],
    this.observationsGenerales = '',
  });

  final String clientId;
  final String clientNom;
  final String mois;
  final String moisLabel;
  final String? codeClient;
  final String? moisSuivantLabel;
  final List<String> sites;
  final List<RapportMensuelLigne> interactionsAdc;
  final List<RapportMensuelLigne> interactionsVdc;
  final List<RapportMensuelLigne> interactionsRefill;
  final List<RapportMensuelLigne> planning;
  final String observationsGenerales;

  int get totalInteractions =>
      interactionsAdc.length + interactionsVdc.length + interactionsRefill.length;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static List<RapportMensuelLigne> _parseLignes(dynamic raw) {
    final rows = <RapportMensuelLigne>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(RapportMensuelLigne.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return rows;
  }

  factory RapportMensuelDetail.fromJson(Map<String, dynamic> m) {
    final rawSites = m['sites'];
    final sites = <String>[];
    if (rawSites is List) {
      for (final e in rawSites) {
        if (e is String && e.trim().isNotEmpty) sites.add(e.trim());
      }
    }
    return RapportMensuelDetail(
      clientId: '${m['client_id'] ?? ''}',
      clientNom: '${m['client_nom'] ?? ''}',
      mois: '${m['mois'] ?? ''}',
      moisLabel: '${m['mois_label'] ?? ''}',
      codeClient: _str(m['code_client']),
      moisSuivantLabel: _str(m['mois_suivant_label']),
      sites: sites,
      interactionsAdc: _parseLignes(m['interactions_adc']),
      interactionsVdc: _parseLignes(m['interactions_vdc']),
      interactionsRefill: _parseLignes(m['interactions_refill']),
      planning: _parseLignes(m['planning']),
      observationsGenerales: '${m['observations_generales_defaut'] ?? ''}',
    );
  }
}
