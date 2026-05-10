import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/bon_commande.dart';
import '../models/demande_a_payer.dart';
import '../models/galerie_fichier.dart';
import '../models/galerie_folder.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AromaApi {
  AromaApi({required this.getToken, http.Client? client})
    : _client = client ?? http.Client();

  final String? Function() getToken;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl;
    final u = Uri.parse('$base$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(
      queryParameters: {...u.queryParameters, ...query},
    );
  }

  /// Nom de fichier HTTP sûr (évite chemins / caractères qui cassent le multipart).
  String? _multipartFilename(String? customName, String sourcePath) {
    String basename(String p) {
      final n = p.replaceAll('\\', '/');
      final i = n.lastIndexOf('/');
      return i >= 0 ? n.substring(i + 1) : n;
    }

    var name = (customName ?? '').trim();
    if (name.isEmpty) return null;
    name = name.replaceAll('\\', '/');
    if (name.contains('/')) {
      name = basename(name);
    }
    name = basename(name);
    if (name.isEmpty) return null;
    // Retire caractères problématiques pour Content-Disposition / stockage.
    name = name.replaceAll(RegExp(r'[\r\n\t\x00-\x1f"]'), '_');
    if (name.length > 200) name = name.substring(0, 200);
    return name.isEmpty ? null : name;
  }

  GalerieFichier _galerieItemFromMap(Map<String, dynamic> map) {
    final lien = map['lien_fichier'];
    if (lien is String && lien.trim().isNotEmpty) {
      map['lien_fichier'] = _toAbsoluteMediaUrl(lien);
    }
    return GalerieFichier.fromJson(map);
  }

  String _toAbsoluteMediaUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final resolved = value.startsWith('/')
        ? base.replace(
            path: value,
            query: null,
            fragment: null,
          )
        : base.resolve(value);
    return resolved.toString();
  }

  Map<String, String> _headers({bool jsonBody = false, bool withAuth = true}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) {
      h['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (withAuth) {
      final t = getToken();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw _errorFromResponse(res);
  }

  Future<void> requestPasswordReset({required String email}) async {
    final res = await _client.post(
      _uri('/auth/forgot-password'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw _errorFromResponse(res);
  }

  Future<String> validateOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post(
      _uri('/auth/validate-otp'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final t = m['reset_token'];
      if (t is String && t.isNotEmpty) return t;
    }
    throw _errorFromResponse(res);
  }

  Future<void> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await _client.post(
      _uri('/auth/reset-password'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw _errorFromResponse(res);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _client.get(_uri('/auth/me'), headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw _errorFromResponse(res);
  }

  Future<List<GalerieFichier>> listGalerie() async {
    final res = await _client.get(_uri('/api/galerie'), headers: _headers());
    if (res.statusCode == 200) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! List<dynamic>) {
          throw ApiException('Réponse galerie invalide (pas une liste).');
        }
        final out = <GalerieFichier>[];
        for (final e in decoded) {
          if (e is! Map) continue;
          try {
            out.add(_galerieItemFromMap(Map<String, dynamic>.from(e)));
          } catch (_) {
            continue;
          }
        }
        return out;
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Impossible de lire la liste galerie: $e');
      }
    }
    throw _errorFromResponse(res);
  }

  Future<List<GalerieFichier>> uploadGalerie(List<String> filePaths) async {
    return uploadGalerieToFolder(filePaths, folder: null);
  }

  Future<List<GalerieFolderRef>> listGalerieFolders() async {
    final res = await _client.get(
      _uri('/api/galerie/folders'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      final byPath = <String, GalerieFolderRef>{};
      for (final entry in list) {
        if (entry is String) {
          final value = entry.trim();
          if (value.isNotEmpty) {
            byPath[value] = GalerieFolderRef(path: value);
          }
          continue;
        }
        if (entry is Map) {
          final m = Map<String, dynamic>.from(entry);
          final raw =
              m['folder'] ??
              m['dossier'] ??
              m['path'] ??
              m['name'];
          if (raw is! String || raw.trim().isEmpty) continue;
          final path = raw.trim();
          final idRaw =
              m['id'] ?? m['folder_id'] ?? m['folderId'] ?? m['uuid'];
          String? id;
          if (idRaw != null) {
            final s = idRaw.toString().trim();
            if (s.isNotEmpty) id = s;
          }
          final prev = byPath[path];
          byPath[path] = GalerieFolderRef(
            path: path,
            id: id ?? prev?.id,
          );
        }
      }
      final out = byPath.values.toList()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      return out;
    }
    throw _errorFromResponse(res);
  }

  Future<GalerieFolderRef> createGalerieFolder(String folder) async {
    final res = await _client.post(
      _uri('/api/galerie/folders'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({'folder': folder}),
    );
    if (res.statusCode == 201) {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final out = m['folder'];
      if (out is String && out.isNotEmpty) {
        final idRaw = m['id'] ?? m['folder_id'] ?? m['folderId'];
        String? id;
        if (idRaw != null) {
          final s = idRaw.toString().trim();
          if (s.isNotEmpty) id = s;
        }
        return GalerieFolderRef(path: out, id: id);
      }
    }
    throw _errorFromResponse(res);
  }

  Future<String> renameGalerieFolder({
    required String fromFolder,
    required String toFolder,
  }) async {
    final res = await _client.patch(
      _uri('/api/galerie/folders/rename'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({'from_folder': fromFolder, 'to_folder': toFolder}),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final out = m['folder'];
      if (out is String && out.isNotEmpty) return out;
    }
    throw _errorFromResponse(res);
  }

  /// Supprime un fichier de la galerie ([DELETE /api/galerie/{id}], 204).
  Future<void> deleteGalerieItem(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Identifiant invalide.');
    }
    final res = await _client.delete(
      _uri('/api/galerie/${Uri.encodeComponent(trimmed)}'),
      headers: _headers(),
    );
    if (res.statusCode == 204) return;
    throw _errorFromResponse(res);
  }

  /// Supprime un dossier ([DELETE /api/galerie/folders], 204).
  /// Quand l’API expose un identifiant de dossier, utiliser [folderId] (UUID) ;
  /// sinon le chemin [folderPath] est envoyé comme avant.
  Future<void> deleteGalerieFolder({
    required String folderPath,
    String? folderId,
  }) async {
    final trimmedPath = folderPath.trim();
    if (trimmedPath.isEmpty) {
      throw ApiException('Dossier invalide.');
    }
    final id = folderId?.trim();
    final query = (id != null && id.isNotEmpty)
        ? <String, String>{'folder_id': id}
        : <String, String>{'folder': trimmedPath};
    final res = await _client.delete(
      _uri('/api/galerie/folders', query),
      headers: _headers(),
    );
    if (res.statusCode == 204) return;
    throw _errorFromResponse(res);
  }

  Future<List<GalerieFichier>> uploadGalerieToFolder(
    List<String> filePaths, {
    String? folder,
    Map<String, String>? fileNamesByPath,
  }) async {
    if (filePaths.isEmpty) {
      return [];
    }
    final uri = _uri('/api/galerie/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers());
    final normalizedFolder = folder?.trim();
    if (normalizedFolder != null && normalizedFolder.isNotEmpty) {
      request.fields['folder'] = normalizedFolder;
    }
    for (final path in filePaths) {
      final customName = fileNamesByPath?[path]?.trim();
      final safeName = _multipartFilename(customName, path);
      try {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            path,
            filename: safeName,
          ),
        );
      } catch (e) {
        throw ApiException('Impossible de lire le fichier pour envoi: $e');
      }
    }
    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! List<dynamic>) {
          throw ApiException('Réponse upload invalide (pas une liste).');
        }
        final out = <GalerieFichier>[];
        for (final e in decoded) {
          if (e is! Map) continue;
          try {
            out.add(_galerieItemFromMap(Map<String, dynamic>.from(e)));
          } catch (_) {
            continue;
          }
        }
        return out;
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Impossible de lire la réponse upload: $e');
      }
    }
    throw _errorFromResponse(res);
  }

  Future<List<DemandeAPayer>> listDemandesAPayer({
    String? statut,
    bool auteurMoi = false,
    String? origine,
  }) async {
    final q = <String, String>{};
    if (statut != null && statut.trim().isNotEmpty) {
      q['statut'] = statut.trim();
    }
    if (auteurMoi) q['auteur_moi'] = 'true';
    if (origine != null && origine.trim().isNotEmpty) {
      q['origine'] = origine.trim();
    }
    final res = await _client.get(
      _uri('/api/caisse/demandes-a-payer', q),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse demandes à payer invalide.');
      }
      final out = <DemandeAPayer>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        try {
          out.add(DemandeAPayer.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          continue;
        }
      }
      return out;
    }
    throw _errorFromResponse(res);
  }

  Future<DemandeAPayer> patchDemandeAPayer(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch(
      _uri('/api/caisse/demandes-a-payer/${Uri.encodeComponent(id)}'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body);
      if (m is Map<String, dynamic>) {
        return DemandeAPayer.fromJson(m);
      }
    }
    throw _errorFromResponse(res);
  }

  /// Upload pièces jointes (retour caisse, etc.) — champ `files`, comme le CRM web.
  Future<List<Map<String, dynamic>>> uploadDemandesAPayerJustificatifs(
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return [];
    final uri = _uri('/api/caisse/demandes-a-payer/justificatifs');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers());
    for (final path in filePaths) {
      final safeName = _multipartFilename(null, path);
      try {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            path,
            filename: safeName,
          ),
        );
      } catch (e) {
        throw ApiException('Impossible de lire le fichier pour envoi: $e');
      }
    }
    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse justificatifs invalide.');
      }
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  Future<List<BonCommandeFournisseurLite>> listBonsCommandeFournisseur() async {
    final res = await _client.get(
      _uri('/api/bons-commande/fournisseur'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse bons fournisseur invalide.');
      }
      final out = <BonCommandeFournisseurLite>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        try {
          out.add(
            BonCommandeFournisseurLite.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (_) {
          continue;
        }
      }
      return out;
    }
    throw _errorFromResponse(res);
  }

  Future<BonCommandeFournisseurLite> patchBonCommandeFournisseur(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch(
      _uri('/api/bons-commande/fournisseur/${Uri.encodeComponent(id)}'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body);
      if (m is Map<String, dynamic>) {
        return BonCommandeFournisseurLite.fromJson(m);
      }
    }
    throw _errorFromResponse(res);
  }

  Future<List<BonCommandeInterneLite>> listBonsCommandeInterne() async {
    final res = await _client.get(
      _uri('/api/bons-commande/interne'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse bons internes invalide.');
      }
      final out = <BonCommandeInterneLite>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        try {
          out.add(
            BonCommandeInterneLite.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (_) {
          continue;
        }
      }
      return out;
    }
    throw _errorFromResponse(res);
  }

  Future<BonCommandeInterneLite> patchBonCommandeInterne(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch(
      _uri('/api/bons-commande/interne/${Uri.encodeComponent(id)}'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body);
      if (m is Map<String, dynamic>) {
        return BonCommandeInterneLite.fromJson(m);
      }
    }
    throw _errorFromResponse(res);
  }

  Future<List<Map<String, dynamic>>> listCollaborateurs() async {
    final res = await _client.get(
      _uri('/api/collaborateurs'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse collaborateurs invalide.');
      }
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  Future<List<Map<String, dynamic>>> listDemandesRh() async {
    final res = await _client.get(
      _uri('/api/demandes'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse demandes RH invalide.');
      }
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  Future<List<Map<String, dynamic>>> listDisciplinesRh() async {
    final res = await _client.get(
      _uri('/api/discipline'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List<dynamic>) {
        throw ApiException('Réponse disciplines RH invalide.');
      }
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  ApiException _errorFromResponse(http.Response res) {
    String msg = 'Erreur réseau (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String) {
          msg = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            msg = first['msg'].toString();
          }
        }
      }
    } catch (_) {
      if (res.body.isNotEmpty) {
        msg = res.body.length > 200
            ? '${res.body.substring(0, 200)}…'
            : res.body;
      }
    }
    return ApiException(msg, statusCode: res.statusCode);
  }

  void close() {
    _client.close();
  }
}
