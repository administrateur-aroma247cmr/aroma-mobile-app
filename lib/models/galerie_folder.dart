/// Dossier galerie renvoyé par l’API (chemin + identifiant serveur optionnel).
class GalerieFolderRef {
  const GalerieFolderRef({required this.path, this.id});

  final String path;
  final String? id;
}
