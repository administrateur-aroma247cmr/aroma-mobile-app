/// Photo d’un critère du rapport (chemin local ou fichier galerie).
class RapportPhotoSlot {
  RapportPhotoSlot({
    this.localPath,
    this.galerieId,
    this.galerieUrl,
    this.observation,
  });

  final String? localPath;
  final String? galerieId;
  final String? galerieUrl;
  final String? observation;

  bool get hasPhoto =>
      (localPath != null && localPath!.isNotEmpty) ||
      (galerieId != null && galerieId!.isNotEmpty);

  bool get hasObservation => (observation ?? '').trim().isNotEmpty;

  RapportPhotoSlot copyWith({
    String? localPath,
    String? galerieId,
    String? galerieUrl,
    String? observation,
    bool clearLocal = false,
    bool clearGalerie = false,
    bool clearObservation = false,
  }) {
    return RapportPhotoSlot(
      localPath: clearLocal ? null : (localPath ?? this.localPath),
      galerieId: clearGalerie ? null : (galerieId ?? this.galerieId),
      galerieUrl: clearGalerie ? null : (galerieUrl ?? this.galerieUrl),
      observation:
          clearObservation ? null : (observation ?? this.observation),
    );
  }

  Map<String, dynamic> toJson() => {
        if (localPath != null) 'local_path': localPath,
        if (galerieId != null) 'galerie_id': galerieId,
        if (galerieUrl != null) 'galerie_url': galerieUrl,
        if (hasObservation) 'observation': observation!.trim(),
      };

  factory RapportPhotoSlot.fromJson(Map<String, dynamic> m) {
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return RapportPhotoSlot(
      localPath: str(m['local_path']),
      galerieId: str(m['galerie_id']),
      galerieUrl: str(m['galerie_url']),
      observation: str(m['observation']),
    );
  }
}

/// Personne accompagnante (aligné retour intervention web).
class RapportContactAccompagnant {
  RapportContactAccompagnant({
    this.contactId,
    this.civilite,
    this.nom,
    this.prenom,
    this.poste,
    this.telephone,
  });

  final String? contactId;
  final String? civilite;
  final String? nom;
  final String? prenom;
  final String? poste;
  final String? telephone;

  bool get hasContent =>
      (contactId ?? '').isNotEmpty ||
      (civilite ?? '').trim().isNotEmpty ||
      (nom ?? '').trim().isNotEmpty ||
      (prenom ?? '').trim().isNotEmpty ||
      (poste ?? '').trim().isNotEmpty ||
      (telephone ?? '').trim().isNotEmpty;

  bool get isComplete => (nom ?? '').trim().isNotEmpty;

  RapportContactAccompagnant copyWith({
    String? contactId,
    String? civilite,
    String? nom,
    String? prenom,
    String? poste,
    String? telephone,
    bool clearContactId = false,
  }) {
    return RapportContactAccompagnant(
      contactId: clearContactId ? null : (contactId ?? this.contactId),
      civilite: civilite ?? this.civilite,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      poste: poste ?? this.poste,
      telephone: telephone ?? this.telephone,
    );
  }

  Map<String, dynamic> toJson() => {
        if (contactId != null) 'contact_id': contactId,
        if (civilite != null) 'civilite': civilite,
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (poste != null) 'poste': poste,
        if (telephone != null) 'telephone': telephone,
      };

  factory RapportContactAccompagnant.fromJson(Map<String, dynamic> m) {
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return RapportContactAccompagnant(
      contactId: str(m['contact_id']),
      civilite: str(m['civilite']),
      nom: str(m['nom']),
      prenom: str(m['prenom']),
      poste: str(m['poste']),
      telephone: str(m['telephone']),
    );
  }
}

/// Ressenti et observation pour un lieu (site ou emplacement).
class RapportLieuDraft {
  RapportLieuDraft({
    required this.lieuKey,
    required this.label,
    this.ressentiArriveeTechnicien,
    this.ressentiDepartTechnicien,
    this.ressentiClient,
    this.observation,
  });

  final String lieuKey;
  final String label;
  final String? ressentiArriveeTechnicien;
  final String? ressentiDepartTechnicien;
  /// Ressenti client au départ (aligné `ressenti_client` intervention).
  final String? ressentiClient;
  final String? observation;

  RapportLieuDraft copyWith({
    String? ressentiArriveeTechnicien,
    String? ressentiDepartTechnicien,
    String? ressentiClient,
    String? observation,
  }) {
    return RapportLieuDraft(
      lieuKey: lieuKey,
      label: label,
      ressentiArriveeTechnicien:
          ressentiArriveeTechnicien ?? this.ressentiArriveeTechnicien,
      ressentiDepartTechnicien:
          ressentiDepartTechnicien ?? this.ressentiDepartTechnicien,
      ressentiClient: ressentiClient ?? this.ressentiClient,
      observation: observation ?? this.observation,
    );
  }

  Map<String, dynamic> toJson() => {
        'lieu_key': lieuKey,
        'label': label,
        if (ressentiArriveeTechnicien != null)
          'ressenti_arrivee_technicien': ressentiArriveeTechnicien,
        if (ressentiDepartTechnicien != null)
          'ressenti_depart_technicien': ressentiDepartTechnicien,
        if (ressentiClient != null) 'ressenti_client': ressentiClient,
        if (observation != null) 'observation': observation,
      };

  factory RapportLieuDraft.fromJson(Map<String, dynamic> m) {
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return RapportLieuDraft(
      lieuKey: '${m['lieu_key'] ?? m['label'] ?? ''}',
      label: '${m['label'] ?? ''}',
      ressentiArriveeTechnicien: str(m['ressenti_arrivee_technicien']),
      ressentiDepartTechnicien: str(m['ressenti_depart_technicien']),
      ressentiClient: str(m['ressenti_client']) ??
          str(m['ressenti_depart_accompagnant']),
      observation: str(m['observation']),
    );
  }
}

String rapportLieuKeyForEmplacement(String? emplacement) {
  final e = (emplacement ?? '').trim();
  return e.isNotEmpty ? e : 'site';
}

List<RapportLieuDraft> buildDefaultRapportLieux({
  required String siteLabel,
  required List<String> emplacements,
}) {
  final uniqueEmplacements = emplacements
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  if (uniqueEmplacements.isEmpty) {
    final label = siteLabel.trim().isNotEmpty ? siteLabel.trim() : 'Site';
    return [RapportLieuDraft(lieuKey: 'site', label: label)];
  }
  return uniqueEmplacements
      .map((e) => RapportLieuDraft(lieuKey: e, label: e))
      .toList();
}

class RapportDiffuseurDraft {
  RapportDiffuseurDraft({
    required this.equipementId,
    required this.label,
    this.lieuKey,
    this.traite = true,
    this.huileSenteur,
    this.huileDesignation,
    this.quantiteMl,
    this.sortieSource,
    Map<String, RapportPhotoSlot>? photos,
    Map<String, String>? values,
  })  : photos = photos ?? {},
        values = values ?? {};

  final String equipementId;
  final String label;
  /// Emplacement du site (`site` si non renseigné).
  final String? lieuKey;
  final bool traite;
  /// Huile à sortir (lecture seule, depuis l’API intervention).
  final String? huileSenteur;
  final String? huileDesignation;
  final double? quantiteMl;
  final String? sortieSource;
  final Map<String, RapportPhotoSlot> photos;
  final Map<String, String> values;

  RapportDiffuseurDraft copyWith({
    String? label,
    String? lieuKey,
    bool? traite,
    String? huileSenteur,
    String? huileDesignation,
    double? quantiteMl,
    String? sortieSource,
    Map<String, RapportPhotoSlot>? photos,
    Map<String, String>? values,
  }) {
    return RapportDiffuseurDraft(
      equipementId: equipementId,
      label: label ?? this.label,
      lieuKey: lieuKey ?? this.lieuKey,
      traite: traite ?? this.traite,
      huileSenteur: huileSenteur ?? this.huileSenteur,
      huileDesignation: huileDesignation ?? this.huileDesignation,
      quantiteMl: quantiteMl ?? this.quantiteMl,
      sortieSource: sortieSource ?? this.sortieSource,
      photos: photos ?? Map<String, RapportPhotoSlot>.from(this.photos),
      values: values ?? Map<String, String>.from(this.values),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipement_id': equipementId,
        'label': label,
        if (lieuKey != null) 'lieu_key': lieuKey,
        'traite': traite,
        if (huileSenteur != null) 'huile_senteur': huileSenteur,
        if (huileDesignation != null) 'huile_designation': huileDesignation,
        if (quantiteMl != null) 'quantite_ml': quantiteMl,
        if (sortieSource != null) 'sortie_source': sortieSource,
        'photos': photos.map((k, v) => MapEntry(k, v.toJson())),
        'values': values,
      };

  factory RapportDiffuseurDraft.fromJson(Map<String, dynamic> m) {
    final rawPhotos = m['photos'];
    final photos = <String, RapportPhotoSlot>{};
    if (rawPhotos is Map) {
      for (final e in rawPhotos.entries) {
        if (e.value is Map) {
          photos[e.key.toString()] = RapportPhotoSlot.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          );
        }
      }
    }
    final rawValues = m['values'];
    final values = <String, String>{};
    if (rawValues is Map) {
      for (final e in rawValues.entries) {
        final v = e.value?.toString().trim();
        if (v != null && v.isNotEmpty) values[e.key.toString()] = v;
      }
    }
    String? strField(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return RapportDiffuseurDraft(
      equipementId: '${m['equipement_id']}',
      label: '${m['label'] ?? ''}',
      lieuKey: m['lieu_key']?.toString(),
      traite: m['traite'] != false,
      huileSenteur: strField(m['huile_senteur']),
      huileDesignation: strField(m['huile_designation']),
      quantiteMl: m['quantite_ml'] == null
          ? null
          : (m['quantite_ml'] is num
              ? (m['quantite_ml'] as num).toDouble()
              : double.tryParse('${m['quantite_ml']}')),
      sortieSource: strField(m['sortie_source']),
      photos: photos,
      values: values,
    );
  }
}

class InterventionRapportDraft {
  InterventionRapportDraft({
    required this.interventionId,
    this.interventionRef,
    RapportPhotoSlot? technicienPhoto,
    RapportContactAccompagnant? contactAccompagnant,
    this.lieux = const [],
    this.diffuseurs = const [],
    this.updatedAt,
  })  : technicienPhoto = technicienPhoto ?? RapportPhotoSlot(),
        contactAccompagnant =
            contactAccompagnant ?? RapportContactAccompagnant();

  final String interventionId;
  final String? interventionRef;
  final RapportPhotoSlot technicienPhoto;
  final RapportContactAccompagnant contactAccompagnant;
  final List<RapportLieuDraft> lieux;
  final List<RapportDiffuseurDraft> diffuseurs;
  final String? updatedAt;

  int countPhotosFilled() {
    var n = technicienPhoto.hasPhoto ? 1 : 0;
    for (final d in diffuseurs) {
      if (!d.traite) continue;
      for (final p in d.photos.values) {
        if (p.hasPhoto) n += 1;
      }
    }
    return n;
  }

  int countPhotosTotal() {
    var n = 1;
    for (final d in diffuseurs) {
      if (!d.traite) continue;
      n += d.photos.length;
    }
    return n;
  }

  InterventionRapportDraft copyWith({
    RapportPhotoSlot? technicienPhoto,
    RapportContactAccompagnant? contactAccompagnant,
    List<RapportLieuDraft>? lieux,
    List<RapportDiffuseurDraft>? diffuseurs,
    String? updatedAt,
  }) {
    return InterventionRapportDraft(
      interventionId: interventionId,
      interventionRef: interventionRef,
      technicienPhoto: technicienPhoto ?? this.technicienPhoto,
      contactAccompagnant: contactAccompagnant ?? this.contactAccompagnant,
      lieux: lieux ?? this.lieux,
      diffuseurs: diffuseurs ?? this.diffuseurs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'intervention_id': interventionId,
        if (interventionRef != null) 'intervention_ref': interventionRef,
        'technicien_photo': technicienPhoto.toJson(),
        'contact_accompagnant': contactAccompagnant.toJson(),
        'lieux': lieux.map((l) => l.toJson()).toList(),
        'diffuseurs': diffuseurs.map((d) => d.toJson()).toList(),
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  factory InterventionRapportDraft.fromJson(Map<String, dynamic> m) {
    final rawDiffuseurs = m['diffuseurs'];
    final diffuseurs = <RapportDiffuseurDraft>[];
    if (rawDiffuseurs is List) {
      for (final e in rawDiffuseurs) {
        if (e is Map) {
          diffuseurs.add(
            RapportDiffuseurDraft.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final rawTech = m['technicien_photo'];
    final rawContact = m['contact_accompagnant'];
    final rawLieux = m['lieux'];
    final lieux = <RapportLieuDraft>[];
    if (rawLieux is List) {
      for (final e in rawLieux) {
        if (e is Map) {
          lieux.add(RapportLieuDraft.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return InterventionRapportDraft(
      interventionId: '${m['intervention_id']}',
      interventionRef: m['intervention_ref']?.toString(),
      technicienPhoto: rawTech is Map
          ? RapportPhotoSlot.fromJson(Map<String, dynamic>.from(rawTech))
          : RapportPhotoSlot(),
      contactAccompagnant: rawContact is Map
          ? RapportContactAccompagnant.fromJson(
              Map<String, dynamic>.from(rawContact),
            )
          : RapportContactAccompagnant(),
      lieux: lieux,
      diffuseurs: diffuseurs,
      updatedAt: m['updated_at']?.toString(),
    );
  }
}
