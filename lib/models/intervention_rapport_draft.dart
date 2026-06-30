/// Photo d’un critère du rapport (chemin local ou fichier galerie).
class RapportPhotoSlot {
  RapportPhotoSlot({
    this.localPath,
    this.galerieId,
    this.galerieUrl,
  });

  final String? localPath;
  final String? galerieId;
  final String? galerieUrl;

  bool get hasPhoto =>
      (localPath != null && localPath!.isNotEmpty) ||
      (galerieId != null && galerieId!.isNotEmpty);

  RapportPhotoSlot copyWith({
    String? localPath,
    String? galerieId,
    String? galerieUrl,
    bool clearLocal = false,
    bool clearGalerie = false,
  }) {
    return RapportPhotoSlot(
      localPath: clearLocal ? null : (localPath ?? this.localPath),
      galerieId: clearGalerie ? null : (galerieId ?? this.galerieId),
      galerieUrl: clearGalerie ? null : (galerieUrl ?? this.galerieUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        if (localPath != null) 'local_path': localPath,
        if (galerieId != null) 'galerie_id': galerieId,
        if (galerieUrl != null) 'galerie_url': galerieUrl,
      };

  factory RapportPhotoSlot.fromJson(Map<String, dynamic> m) {
    String? str(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return RapportPhotoSlot(
      localPath: str(m['local_path']),
      galerieId: str(m['galerie_id']),
      galerieUrl: str(m['galerie_url']),
    );
  }
}

class RapportDiffuseurDraft {
  RapportDiffuseurDraft({
    required this.equipementId,
    required this.label,
    this.traite = true,
    Map<String, RapportPhotoSlot>? photos,
    Map<String, String>? values,
  })  : photos = photos ?? {},
        values = values ?? {};

  final String equipementId;
  final String label;
  final bool traite;
  final Map<String, RapportPhotoSlot> photos;
  final Map<String, String> values;

  RapportDiffuseurDraft copyWith({
    bool? traite,
    Map<String, RapportPhotoSlot>? photos,
    Map<String, String>? values,
  }) {
    return RapportDiffuseurDraft(
      equipementId: equipementId,
      label: label,
      traite: traite ?? this.traite,
      photos: photos ?? Map<String, RapportPhotoSlot>.from(this.photos),
      values: values ?? Map<String, String>.from(this.values),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipement_id': equipementId,
        'label': label,
        'traite': traite,
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
    return RapportDiffuseurDraft(
      equipementId: '${m['equipement_id']}',
      label: '${m['label'] ?? ''}',
      traite: m['traite'] != false,
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
    this.diffuseurs = const [],
    this.updatedAt,
  }) : technicienPhoto = technicienPhoto ?? RapportPhotoSlot();

  final String interventionId;
  final String? interventionRef;
  final RapportPhotoSlot technicienPhoto;
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
    List<RapportDiffuseurDraft>? diffuseurs,
    String? updatedAt,
  }) {
    return InterventionRapportDraft(
      interventionId: interventionId,
      interventionRef: interventionRef,
      technicienPhoto: technicienPhoto ?? this.technicienPhoto,
      diffuseurs: diffuseurs ?? this.diffuseurs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'intervention_id': interventionId,
        if (interventionRef != null) 'intervention_ref': interventionRef,
        'technicien_photo': technicienPhoto.toJson(),
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
    return InterventionRapportDraft(
      interventionId: '${m['intervention_id']}',
      interventionRef: m['intervention_ref']?.toString(),
      technicienPhoto: rawTech is Map
          ? RapportPhotoSlot.fromJson(Map<String, dynamic>.from(rawTech))
          : RapportPhotoSlot(),
      diffuseurs: diffuseurs,
      updatedAt: m['updated_at']?.toString(),
    );
  }
}
