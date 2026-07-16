import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Capture photo compressée partagée (rapport, galerie, réparations).
///
/// 1) Resize + JPEG via [image_picker] (~1600 px, quality 75)
/// 2) Si le fichier dépasse encore [maxBytes], recompression JPEG ciblée
class AppPhotoCapture {
  AppPhotoCapture._();

  static const double maxDimension = 1600;
  static const int imageQuality = 75;

  /// Plafond soft après capture (évite les outliers OEM encore trop lourds).
  static const int maxBytes = 600 * 1024;

  static final ImagePicker _picker = ImagePicker();

  /// Une photo (caméra ou galerie). `null` si annulé.
  static Future<String?> pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: imageQuality,
      );
      if (file == null) return null;
      return _ensureUnderMaxBytes(file.path);
    } on AppPhotoCaptureException {
      rethrow;
    } catch (e) {
      throw AppPhotoCaptureException(
        'Impossible d’obtenir la photo. Vérifiez l’accès caméra / galerie.',
        cause: e,
      );
    }
  }

  /// Plusieurs photos depuis la galerie. Liste vide si annulé.
  static Future<List<String>> pickMulti() async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: imageQuality,
      );
      if (files.isEmpty) return const [];
      final out = <String>[];
      for (final f in files) {
        if (f.path.isEmpty) continue;
        out.add(await _ensureUnderMaxBytes(f.path));
      }
      return out;
    } on AppPhotoCaptureException {
      rethrow;
    } catch (e) {
      throw AppPhotoCaptureException(
        'Impossible d’obtenir les photos. Vérifiez l’accès galerie.',
        cause: e,
      );
    }
  }

  /// Recompresse seulement si nécessaire. En cas d’échec → chemin d’origine.
  static Future<String> _ensureUnderMaxBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return path;

    final initialSize = await file.length();
    if (initialSize <= maxBytes) return path;

    var quality = 70;
    var maxSide = maxDimension.round();
    String currentPath = path;
    var currentSize = initialSize;

    // Quelques passes rapides — ne bloque pas longtemps le technicien.
    for (var attempt = 0; attempt < 3 && currentSize > maxBytes; attempt++) {
      final outPath =
          '${Directory.systemTemp.path}/aroma_photo_${DateTime.now().microsecondsSinceEpoch}_$attempt.jpg';
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          currentPath,
          outPath,
          quality: quality,
          minWidth: maxSide,
          minHeight: maxSide,
          format: CompressFormat.jpeg,
        );
        if (result == null) break;
        final nextSize = await File(result.path).length();
        // Garde seulement si on a vraiment réduit.
        if (nextSize < currentSize) {
          currentPath = result.path;
          currentSize = nextSize;
        } else {
          break;
        }
      } catch (_) {
        // Compresseur indisponible / OEM : on garde le meilleur chemin actuel.
        break;
      }
      quality = (quality - 15).clamp(35, 75);
      maxSide = (maxSide * 0.85).round().clamp(900, 1600);
    }

    return currentPath;
  }
}

/// Alias rétrocompat pour le parcours rapport.
typedef RapportPhotoCapture = AppPhotoCapture;

class AppPhotoCaptureException implements Exception {
  AppPhotoCaptureException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Alias rétrocompat.
typedef RapportPhotoCaptureException = AppPhotoCaptureException;
