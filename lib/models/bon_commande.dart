class BonCommandeLigneLite {
  BonCommandeLigneLite({
    required this.ref,
    required this.designation,
    required this.quantite,
    this.montant,
    this.prixTransport,
  });

  final String? ref;
  final String? designation;
  final double quantite;
  final double? montant;
  final double? prixTransport;

  factory BonCommandeLigneLite.fromJson(Map<String, dynamic> m) {
    double q(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    double? opt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    return BonCommandeLigneLite(
      ref: m['ref'] is String ? m['ref'] as String : null,
      designation: m['designation'] is String ? m['designation'] as String : null,
      quantite: q(m['quantite']),
      montant: opt(m['montant']),
      prixTransport: opt(m['prix_transport']),
    );
  }
}

class BonCommandeFournisseurLite {
  BonCommandeFournisseurLite({
    required this.id,
    required this.reference,
    required this.fournisseurNom,
    required this.statut,
    this.montantCommande,
    this.montantTransport,
    this.lignes = const [],
  });

  final String id;
  final String reference;
  final String fournisseurNom;
  final String statut;
  final double? montantCommande;
  final double? montantTransport;
  final List<BonCommandeLigneLite> lignes;

  static double? _opt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory BonCommandeFournisseurLite.fromJson(Map<String, dynamic> m) {
    final rawL = m['lignes'];
    final lignes = <BonCommandeLigneLite>[];
    if (rawL is List) {
      for (final e in rawL) {
        if (e is Map) {
          lignes.add(
            BonCommandeLigneLite.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return BonCommandeFournisseurLite(
      id: '${m['id']}',
      reference: '${m['reference'] ?? ''}',
      fournisseurNom: '${m['fournisseur_nom'] ?? ''}',
      statut: '${m['statut'] ?? ''}',
      montantCommande: _opt(m['montant_commande']),
      montantTransport: _opt(m['montant_transport']),
      lignes: lignes,
    );
  }

  double get totalCommandeTransport {
    if (montantCommande != null || montantTransport != null) {
      return (montantCommande ?? 0) + (montantTransport ?? 0);
    }
    double cmd = 0;
    double tr = 0;
    for (final l in lignes) {
      cmd += l.montant ?? 0;
      tr += l.prixTransport ?? 0;
    }
    return cmd + tr;
  }
}

class BonCommandeInterneLite {
  BonCommandeInterneLite({
    required this.id,
    required this.reference,
    required this.demande,
    required this.description,
    required this.statut,
    this.collaborateurNom,
    this.pourQuiClientNom,
    this.pourQuiProspectNom,
    this.pourQuiType,
    this.lignes = const [],
  });

  final String id;
  final String reference;
  final String demande;
  final String description;
  final String statut;
  final String? collaborateurNom;
  final String? pourQuiClientNom;
  final String? pourQuiProspectNom;
  final String? pourQuiType;
  final List<BonCommandeLigneLite> lignes;

  factory BonCommandeInterneLite.fromJson(Map<String, dynamic> m) {
    final rawL = m['lignes'];
    final lignes = <BonCommandeLigneLite>[];
    if (rawL is List) {
      for (final e in rawL) {
        if (e is Map) {
          lignes.add(
            BonCommandeLigneLite.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return BonCommandeInterneLite(
      id: '${m['id']}',
      reference: '${m['reference'] ?? ''}',
      demande: '${m['demande'] ?? ''}',
      description: '${m['description'] ?? ''}',
      statut: '${m['statut'] ?? ''}',
      collaborateurNom:
          m['collaborateur_nom'] is String ? m['collaborateur_nom'] as String : null,
      pourQuiClientNom:
          m['pour_qui_client_nom'] is String ? m['pour_qui_client_nom'] as String : null,
      pourQuiProspectNom:
          m['pour_qui_prospect_nom'] is String ? m['pour_qui_prospect_nom'] as String : null,
      pourQuiType: m['pour_qui_type'] is String ? m['pour_qui_type'] as String : null,
      lignes: lignes,
    );
  }

  String get pourQuiLabel {
    if (pourQuiType == 'client' && (pourQuiClientNom ?? '').isNotEmpty) {
      return pourQuiClientNom!;
    }
    if (pourQuiType == 'prospect' && (pourQuiProspectNom ?? '').isNotEmpty) {
      return pourQuiProspectNom!;
    }
    if (pourQuiType == 'jpc') return 'JPC';
    return '—';
  }
}
