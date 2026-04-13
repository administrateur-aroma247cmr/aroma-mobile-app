class GalerieFichier {
  const GalerieFichier({
    required this.id,
    required this.lienFichier,
    this.nomFichier,
    this.mimeType,
    this.dateUpload,
    this.createdAt,
    this.uploadedByUserId,
  });

  final String id;
  final String lienFichier;
  final String? nomFichier;
  final String? mimeType;
  final DateTime? dateUpload;
  final DateTime? createdAt;
  final String? uploadedByUserId;

  factory GalerieFichier.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v is String) {
        return DateTime.tryParse(v);
      }
      return null;
    }

    return GalerieFichier(
      id: json['id'] as String,
      lienFichier: json['lien_fichier'] as String,
      nomFichier: json['nom_fichier'] as String?,
      mimeType: json['mime_type'] as String?,
      dateUpload: parseDt(json['date_upload']),
      createdAt: parseDt(json['created_at']),
      uploadedByUserId: json['uploaded_by_user_id'] as String?,
    );
  }

  bool get isVideo {
    final m = mimeType?.toLowerCase() ?? '';
    final n = nomFichier?.toLowerCase() ?? '';
    return m.startsWith('video/') ||
        n.endsWith('.mp4') ||
        n.endsWith('.mov') ||
        n.endsWith('.webm');
  }
}
