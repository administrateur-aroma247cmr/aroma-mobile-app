import '../config/app_config.dart';

String? _extractDriveFileId(String path) {
  final m1 = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(path);
  if (m1 != null) return m1.group(1);
  final m2 = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(path);
  if (m2 != null) return m2.group(1);
  final m3 = RegExp(r'/uc\?.*id=([a-zA-Z0-9_-]+)').firstMatch(path);
  if (m3 != null) return m3.group(1);
  return null;
}

/// URL pour ouvrir le document (navigateur / visionneuse externe), comme `getDocumentOpenUrl` du CRM.
String documentOpenUrl(String path) {
  final p = path.trim();
  if (p.isEmpty) return p;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final normalized = p.startsWith('/') ? p : '/$p';
  return '$base$normalized';
}

/// URL de prévisualisation (ex. iframe Drive) — utile si on affiche une preview native plus tard.
String documentPreviewUrl(String path) {
  final p = path.trim();
  if (p.isEmpty) return p;
  if (p.startsWith('http://') || p.startsWith('https://')) {
    final id = _extractDriveFileId(p);
    if (id != null) {
      return 'https://drive.google.com/file/d/$id/preview';
    }
    return p;
  }
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final normalized = p.startsWith('/') ? p : '/$p';
  return '$base$normalized';
}
