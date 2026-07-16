import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/galerie_fichier.dart';
import '../providers/auth_provider.dart';
import '../services/aroma_api.dart';
import '../theme/aroma_theme.dart';
import '../utils/rapport_photo_capture.dart';
import '../widgets/modern_bottom_sheet.dart';

/// Aligné sur le CRM web (rôle privilégié ou auteur de l’upload).
bool _galerieFileCanDelete(AuthProvider auth, GalerieFichier f) {
  final myId = auth.me?['id']?.toString();
  final up = f.uploadedByUserId;
  final isUploader = myId != null && up != null && up == myId;
  return auth.canDeleteGalerieFile(isUploader: isUploader);
}

enum _GallerySort { nameAsc, nameDesc, newest, oldest }

class GalerieScreen extends StatefulWidget {
  const GalerieScreen({super.key, this.embedded = false});

  /// Dans [MainShell] : pas de barre propre (AppBar / déconnexion gérés au-dessus).
  final bool embedded;

  @override
  State<GalerieScreen> createState() => GalerieScreenState();
}

class GalerieScreenState extends State<GalerieScreen> {
  static const int _maxFileSizeBytes = 15 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
    '.pdf',
  };

  final _picker = ImagePicker();
  Future<List<GalerieFichier>>? _future;
  bool _uploading = false;
  bool _loadingFolders = false;
  List<String> _folders = const [];
  /// Clés = chemins normalisés ([_normalizeFolder]), valeurs = UUID dossier (API).
  final Map<String, String> _folderIdsByPath = {};
  String? _currentFolder;
  _GallerySort _sort = _GallerySort.nameAsc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final api = context.read<AuthProvider>().api;
    setState(() {
      _future = api.listGalerie();
    });
    _reloadFolders();
  }

  /// Utilisé par [MainShell] (bouton actualiser de l’AppBar).
  void reload() => _reload();

  Future<void> _reloadFolders() async {
    final api = context.read<AuthProvider>().api;
    setState(() => _loadingFolders = true);
    try {
      final refs = await api.listGalerieFolders();
      if (!mounted) return;
      final folderPaths = refs.map((r) => r.path).toList();
      final idUpdates = <String, String>{};
      for (final r in refs) {
        final n = _normalizeFolder(r.path);
        if (n.isNotEmpty && r.id != null && r.id!.trim().isNotEmpty) {
          idUpdates[n] = r.id!.trim();
        }
      }
      // Ne pas réutiliser l’ancien [_folders] : sinon les dossiers supprimés
      // côté API restent affichés. On reconstruit depuis l’API + les chemins
      // encore présents dans les fichiers de la galerie.
      final fromApi = folderPaths.expand(_expandFolderAncestors).toSet();
      final fromFiles = <String>{};
      try {
        final items = await _future;
        if (items != null) {
          for (final item in items) {
            final value = item.dossier?.trim();
            if (value != null && value.isNotEmpty) {
              fromFiles.addAll(_expandFolderAncestors(value));
            }
          }
        }
      } catch (_) {
        // Liste galerie indisponible : on garde uniquement l’API.
      }
      final mergedSet = {...fromApi, ...fromFiles};
      final mergedFolders = mergedSet.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _folders = mergedFolders;
        _folderIdsByPath.removeWhere((k, _) => !mergedSet.contains(k));
        _folderIdsByPath.addAll(idUpdates);
        if (_currentFolder != null && !_folders.contains(_currentFolder)) {
          _currentFolder = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les dossiers.')),
      );
    } finally {
      if (mounted) setState(() => _loadingFolders = false);
    }
  }

  Future<void> _confirmDeleteFile(GalerieFichier f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce fichier ?'),
        content: Text(
          f.nomFichier != null && f.nomFichier!.trim().isNotEmpty
              ? '« ${f.nomFichier} » sera supprimé définitivement.'
              : 'Ce document sera supprimé définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = context.read<AuthProvider>().api;
    try {
      await api.deleteGalerieItem(f.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _confirmDeleteFolder(String folderPath) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le dossier ?'),
        content: Text(
          'Le dossier « ${_folderDisplayName(folderPath)} » et tout son contenu '
          'seront supprimés définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = context.read<AuthProvider>().api;
    try {
      final norm = _normalizeFolder(folderPath);
      await api.deleteGalerieFolder(
        folderPath: folderPath,
        folderId: _folderIdsByPath[norm],
      );
      if (!mounted) return;
      final normalizedCurrent = _normalizeFolder(_currentFolder);
      final normalizedDeleted = _normalizeFolder(folderPath);
      if (normalizedCurrent.isNotEmpty &&
          (normalizedCurrent == normalizedDeleted ||
              normalizedCurrent.startsWith('$normalizedDeleted/'))) {
        setState(() => _currentFolder = _parentFolderOf(folderPath));
      }
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier supprimé.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<List<String>> _collectKnownFolders() async {
    final folders = <String>{
      ..._folders.expand(_expandFolderAncestors),
    };
    try {
      final items = await _future;
      if (items != null) {
        for (final item in items) {
          final value = item.dossier?.trim();
          if (value != null && value.isNotEmpty) {
            folders.addAll(_expandFolderAncestors(value));
          }
        }
      }
    } catch (_) {
      // Ignore: on garde les dossiers API déjà connus.
    }
    final out = folders.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  String _extensionOf(String path) {
    final lower = path.toLowerCase();
    final sep = lower.lastIndexOf('.');
    if (sep <= 0 || sep == lower.length - 1) return '';
    return lower.substring(sep);
  }

  String _fileNameOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  String _fileStemOf(String filename) {
    final idx = filename.lastIndexOf('.');
    if (idx <= 0) return filename;
    return filename.substring(0, idx);
  }

  Future<Map<String, String>?> _askRenameBeforeUpload(List<String> paths) async {
    if (paths.isEmpty) return const {};
    final fileNames = paths.map(_fileNameOf).toList();
    final controllers = fileNames
        .map((name) => TextEditingController(text: _fileStemOf(name)))
        .toList();

    try {
      final renamed = await showDialog<Map<String, String>>(
        context: context,
        barrierColor: Colors.black38,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Renommer avant envoi'),
            content: SizedBox(
              width: 420,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: paths.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final originalName = fileNames[i];
                  final ext = _extensionOf(originalName);
                  return TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: ext.isEmpty
                          ? originalName
                          : '$originalName ($ext)',
                      hintText: 'Nom du fichier',
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final out = <String, String>{};
                  for (var i = 0; i < paths.length; i++) {
                    final originalName = fileNames[i];
                    final originalExt = _extensionOf(originalName);
                    var typed = controllers[i].text.trim();
                    if (typed.isEmpty) {
                      typed = _fileStemOf(originalName);
                    }
                    if (originalExt.isNotEmpty &&
                        !typed.toLowerCase().endsWith(originalExt)) {
                      typed = '$typed$originalExt';
                    }
                    out[paths[i]] = typed;
                  }
                  Navigator.pop(ctx, out);
                },
                child: const Text('Continuer'),
              ),
            ],
          );
        },
      );
      return renamed;
    } finally {
      await _waitDialogFrame();
      for (final c in controllers) {
        c.dispose();
      }
    }
  }

  String _normalizeFolder(String? folder) {
    if (folder == null) return '';
    final normalized = folder.trim().replaceAll('\\', '/');
    return normalized.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  String _folderDisplayName(String? folder) {
    final normalized = _normalizeFolder(folder);
    if (normalized.isEmpty) return 'Racine';
    return normalized.split('/').last;
  }

  Set<String> _expandFolderAncestors(String? folder) {
    final normalized = _normalizeFolder(folder);
    if (normalized.isEmpty) return const {};
    final parts = normalized.split('/').where((p) => p.trim().isNotEmpty).toList();
    final out = <String>{};
    for (var i = 1; i <= parts.length; i++) {
      out.add(parts.sublist(0, i).join('/'));
    }
    return out;
  }

  String? _parentFolderOf(String? folder) {
    final normalized = _normalizeFolder(folder);
    if (normalized.isEmpty) return null;
    final idx = normalized.lastIndexOf('/');
    if (idx <= 0) return null;
    return normalized.substring(0, idx);
  }

  List<String> _directChildFolders(List<String> allFolders, String? current) {
    final parent = _normalizeFolder(current);
    final out = <String>{};
    for (final raw in allFolders) {
      final folder = _normalizeFolder(raw);
      if (folder.isEmpty) continue;
      if (parent.isEmpty) {
        final cut = folder.split('/').first.trim();
        if (cut.isNotEmpty) out.add(cut);
        continue;
      }
      if (!folder.startsWith('$parent/')) continue;
      final suffix = folder.substring(parent.length + 1);
      if (suffix.isEmpty) continue;
      final direct = suffix.split('/').first.trim();
      if (direct.isNotEmpty) out.add('$parent/$direct');
    }
    final list = out.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<GalerieFichier> _filesInCurrentFolder(List<GalerieFichier> items) {
    final current = _normalizeFolder(_currentFolder);
    final out = items.where((item) {
      final itemFolder = _normalizeFolder(item.dossier);
      return current == itemFolder;
    }).toList();
    int byName(GalerieFichier a, GalerieFichier b) {
      final an = (a.nomFichier ?? a.id).toLowerCase();
      final bn = (b.nomFichier ?? b.id).toLowerCase();
      return an.compareTo(bn);
    }

    DateTime? dt(GalerieFichier f) => f.dateUpload ?? f.createdAt;

    switch (_sort) {
      case _GallerySort.nameAsc:
        out.sort(byName);
        break;
      case _GallerySort.nameDesc:
        out.sort((a, b) => byName(b, a));
        break;
      case _GallerySort.newest:
        out.sort((a, b) {
          final ad = dt(a);
          final bd = dt(b);
          if (ad == null && bd == null) return byName(a, b);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
        break;
      case _GallerySort.oldest:
        out.sort((a, b) {
          final ad = dt(a);
          final bd = dt(b);
          if (ad == null && bd == null) return byName(a, b);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
        break;
    }
    return out;
  }

  List<String> _breadcrumbParts() {
    final normalized = _normalizeFolder(_currentFolder);
    if (normalized.isEmpty) return const [];
    return normalized.split('/').where((e) => e.trim().isNotEmpty).toList();
  }

  Future<void> _uploadPaths(
    List<String> paths, {
    String? folder,
    Map<String, String>? fileNamesByPath,
  }) async {
    if (paths.isEmpty) return;
    final validPaths = <String>[];
    final rejected = <String>[];
    for (final p in paths) {
      try {
        final ext = _extensionOf(p);
        if (!_allowedExtensions.contains(ext)) {
          rejected.add('${_fileNameOf(p)} (type non autorise)');
          continue;
        }
        final file = File(p);
        if (!await file.exists()) {
          rejected.add('${_fileNameOf(p)} (introuvable)');
          continue;
        }
        final size = await file.length();
        if (size > _maxFileSizeBytes) {
          rejected.add('${_fileNameOf(p)} (> 15 Mo)');
          continue;
        }
        validPaths.add(p);
      } catch (e) {
        rejected.add('${_fileNameOf(p)} ($e)');
      }
    }

    if (rejected.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fichiers ignores: ${rejected.join(', ')}',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (validPaths.isEmpty) return;

    final api = context.read<AuthProvider>().api;
    setState(() => _uploading = true);
    try {
      await api.uploadGalerieToFolder(
        validPaths,
        folder: folder,
        fileNamesByPath: fileNamesByPath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${validPaths.length} fichier(s) envoye(s).')),
        );
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec de l’envoi : $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _createFolderDialog({String? parentFolder}) async {
    final folder = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => _CreateFolderDialog(
        parentFolder: parentFolder,
      ),
    );
    if (folder == null || folder.isEmpty) return null;
    final api = context.read<AuthProvider>().api;
    try {
      final created = await api.createGalerieFolder(folder);
      if (!mounted) return null;
      await _reloadFolders();
      if (!mounted) return null;
      final createdPath = created.path;
      final createdNorm = _normalizeFolder(createdPath);
      if (created.id != null && createdNorm.isNotEmpty) {
        setState(() {
          _folderIdsByPath[createdNorm] = created.id!.trim();
        });
      }
      if (!_folders.contains(createdPath)) {
        setState(() {
          _folders = <String>{..._folders, createdPath}.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        });
      }
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Dossier cree: $createdPath')));
      return createdPath;
    } on ApiException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Erreur creation dossier: $e')));
      return null;
    }
  }

  Future<String?> _askUploadDestination() async {
    await _reloadFolders();
    if (!mounted) return null;
    const rootSentinel = '__ROOT__';
    String selected = _normalizeFolder(_currentFolder).isEmpty
        ? rootSentinel
        : _normalizeFolder(_currentFolder);
    List<String> localFolders = await _collectKnownFolders();
    final destination = await showModernBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return ModernBottomSheetShell(
          initialChildSize: 0.55,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (_, scrollController) {
              return StatefulBuilder(
                builder: (context, setSheetState) {
                  final bottom = MediaQuery.paddingOf(context).bottom;
                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
                    children: [
                      const SizedBox(height: 10),
                      modernSheetDragHandle(),
                      const SizedBox(height: 16),
                      ModernSheetHeader(
                        title: 'Où insérer les fichiers ?',
                        theme: ModernSheetThemes.galerie,
                      ),
                      const SizedBox(height: 16),
                      _FolderChoiceTile(
                        label: 'Racine (/)',
                        selected: selected == rootSentinel,
                        onTap: () =>
                            setSheetState(() => selected = rootSentinel),
                      ),
                      ...localFolders.map(
                        (f) => _FolderChoiceTile(
                          label: _folderDisplayName(f),
                          selected: selected == f,
                          onTap: () => setSheetState(() => selected = f),
                        ),
                      ),
                      if (localFolders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Aucun dossier detecte pour le moment.\n'
                            'Vous pouvez en creer un.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final selectedFolder = selected == rootSentinel
                                    ? null
                                    : selected;
                                final created = await _createFolderDialog(
                                  parentFolder: selectedFolder,
                                );
                                if (created == null) return;
                                localFolders = await _collectKnownFolders();
                                if (!localFolders.contains(created)) {
                                  localFolders.add(created);
                                  localFolders.sort(
                                    (a, b) => a.toLowerCase().compareTo(
                                      b.toLowerCase(),
                                    ),
                                  );
                                }
                                setSheetState(() => selected = created);
                              },
                              icon: const Icon(Icons.create_new_folder_outlined),
                              label: const Text('Nouveau dossier'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(ctx, selected),
                              icon: const Icon(Icons.check),
                              label: const Text('Continuer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
    if (destination == null) return null;
    return destination == rootSentinel ? null : destination;
  }

  Future<String?> _resolveUploadDestination() async {
    final current = _normalizeFolder(_currentFolder);
    if (current.isNotEmpty) {
      return current;
    }
    return _askUploadDestination();
  }

  Future<void> _waitDialogFrame() async {
    // Evite les conflits de scope build juste après fermeture d'une modale.
    // On laisse Flutter finir la frame courante + le cycle clavier/insets.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    final x = await _picker.pickVideo(source: source);
    if (x == null) return;
    final fileNamesByPath = await _askRenameBeforeUpload([x.path]);
    if (fileNamesByPath == null) return;
    await _waitDialogFrame();
    if (!mounted) return;
    final folder = await _resolveUploadDestination();
    if (!mounted) return;
    await _uploadPaths([x.path], folder: folder, fileNamesByPath: fileNamesByPath);
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final path = await AppPhotoCapture.pick(source);
      if (path == null) return;
      final fileNamesByPath = await _askRenameBeforeUpload([path]);
      if (fileNamesByPath == null) return;
      await _waitDialogFrame();
      if (!mounted) return;
      final folder = await _resolveUploadDestination();
      if (!mounted) return;
      await _uploadPaths([path], folder: folder, fileNamesByPath: fileNamesByPath);
    } on AppPhotoCaptureException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _pickMultipleMedia() async {
    try {
      final paths = await AppPhotoCapture.pickMulti();
      if (paths.isEmpty) return;
      final fileNamesByPath = await _askRenameBeforeUpload(paths);
      if (fileNamesByPath == null) return;
      await _waitDialogFrame();
      if (!mounted) return;
      final folder = await _resolveUploadDestination();
      if (!mounted) return;
      await _uploadPaths(paths, folder: folder, fileNamesByPath: fileNamesByPath);
    } on AppPhotoCaptureException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (r == null || r.files.isEmpty) return;
    final paths = r.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
    final fileNamesByPath = await _askRenameBeforeUpload(paths);
    if (fileNamesByPath == null) return;
    await _waitDialogFrame();
    if (!mounted) return;
    final folder = await _resolveUploadDestination();
    if (!mounted) return;
    await _uploadPaths(paths, folder: folder, fileNamesByPath: fileNamesByPath);
  }

  void _showAddSheet() {
    final current = _normalizeFolder(_currentFolder);
    final uploadTargetLabel = current.isEmpty ? 'Racine' : current;
    showModernActionSheet(
      context: context,
      title: 'Ajouter des fichiers',
      subtitle: 'Destination: $uploadTargetLabel',
      theme: ModernSheetThemes.galerie,
      actions: [
        _UploadActionTile(
          icon: Icons.photo_camera_outlined,
          title: 'Prendre une photo',
          subtitle: 'Ouvre la camera',
          onTap: () {
            Navigator.pop(context);
            _pickAndUploadPhoto(ImageSource.camera);
          },
        ),
        _UploadActionTile(
          icon: Icons.video_library_outlined,
          title: 'Video depuis l’appareil',
          subtitle: 'Selectionner une video',
          onTap: () {
            Navigator.pop(context);
            _pickAndUploadVideo(ImageSource.gallery);
          },
        ),
        _UploadActionTile(
          icon: Icons.collections_outlined,
          title: 'Photos (plusieurs)',
          subtitle: 'Sélection multiple compressée',
          onTap: () {
            Navigator.pop(context);
            _pickMultipleMedia();
          },
        ),
        _UploadActionTile(
          icon: Icons.attach_file,
          title: 'Fichiers',
          subtitle: 'PDF, images, documents',
          onTap: () {
            Navigator.pop(context);
            _pickFiles();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.select<AuthProvider, String?>((a) => a.token);
    final imageHeaders = (token != null && token.isNotEmpty)
        ? <String, String>{'Authorization': 'Bearer $token'}
        : null;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Ma galerie'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _uploading ? null : _reload,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => _reload(),
            child: FutureBuilder<List<GalerieFichier>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Impossible de charger la galerie.\n${snap.error}',
                        ),
                      ),
                    ],
                  );
                }
                final items = snap.data ?? [];
                if (_loadingFolders && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final auth = context.read<AuthProvider>();
                final visibleFiles = _filesInCurrentFolder(items);
                final childFolders = _directChildFolders(_folders, _currentFolder);
                final atRoot = _normalizeFolder(_currentFolder).isEmpty;
                return items.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun fichier pour l’instant.\n'
                          'Ajoutez une photo, une video ou un fichier.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: Row(
                              children: [
                                if (!atRoot)
                                  IconButton(
                                    onPressed: () {
                                      setState(
                                        () =>
                                            _currentFolder = _parentFolderOf(
                                              _currentFolder,
                                            ),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    tooltip: 'Dossier parent',
                                  ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() => _currentFolder = null);
                                          },
                                          icon: const Icon(
                                            Icons.home_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Racine'),
                                        ),
                                        ...() {
                                          final parts = _breadcrumbParts();
                                          final widgets = <Widget>[];
                                          var built = '';
                                          for (final p in parts) {
                                            built = built.isEmpty
                                                ? p
                                                : '$built/$p';
                                            final path = built;
                                            widgets.add(
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 2,
                                                ),
                                                child: Icon(
                                                  Icons.chevron_right,
                                                  size: 18,
                                                ),
                                              ),
                                            );
                                            widgets.add(
                                              TextButton(
                                                onPressed: () {
                                                  setState(
                                                    () => _currentFolder = path,
                                                  );
                                                },
                                                child: Text(p),
                                              ),
                                            );
                                          }
                                          return widgets;
                                        }(),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuButton<_GallerySort>(
                                  tooltip: 'Trier',
                                  icon: const Icon(Icons.sort),
                                  initialValue: _sort,
                                  onSelected: (value) {
                                    setState(() => _sort = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _GallerySort.nameAsc,
                                      child: Text('Nom A -> Z'),
                                    ),
                                    PopupMenuItem(
                                      value: _GallerySort.nameDesc,
                                      child: Text('Nom Z -> A'),
                                    ),
                                    PopupMenuItem(
                                      value: _GallerySort.newest,
                                      child: Text('Plus recents'),
                                    ),
                                    PopupMenuItem(
                                      value: _GallerySort.oldest,
                                      child: Text('Plus anciens'),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Nouveau dossier',
                                  icon: const Icon(Icons.create_new_folder_outlined),
                                  onPressed: _uploading
                                      ? null
                                      : () async {
                                          final created = await _createFolderDialog(
                                            parentFolder: _currentFolder,
                                          );
                                          if (created != null && mounted) {
                                            setState(() => _currentFolder = created);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: (childFolders.isEmpty && visibleFiles.isEmpty)
                                ? const Center(
                                    child: Text(
                                      'Dossier vide.\nAjoutez des fichiers ou créez un sous-dossier.',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 0.95,
                                        ),
                                    itemCount:
                                        childFolders.length + visibleFiles.length,
                                    itemBuilder: (context, i) {
                                      if (i < childFolders.length) {
                                        final folder = childFolders[i];
                                        return _FolderGridTile(
                                          folder: folder,
                                          onTap: () {
                                            setState(
                                              () => _currentFolder = folder,
                                            );
                                          },
                                          onDelete: () =>
                                              _confirmDeleteFolder(folder),
                                        );
                                      }
                                      final g = visibleFiles[i - childFolders.length];
                                      return _GalerieTile(
                                        fichier: g,
                                        imageHeaders: imageHeaders,
                                        canDelete: _galerieFileCanDelete(auth, g),
                                        onDeleteRequested: () =>
                                            _confirmDeleteFile(g),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
              },
            ),
          ),
          if (_uploading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Envoi en cours…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-galerie-add',
        onPressed: _uploading ? null : _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _GalerieTile extends StatelessWidget {
  const _GalerieTile({
    required this.fichier,
    this.imageHeaders,
    this.canDelete = false,
    this.onDeleteRequested,
  });

  final GalerieFichier fichier;
  final Map<String, String>? imageHeaders;
  final bool canDelete;
  final VoidCallback? onDeleteRequested;

  bool get _isImage {
    final mime = (fichier.mimeType ?? '').toLowerCase();
    if (mime.startsWith('image/')) return true;
    final name = (fichier.nomFichier ?? '').toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    final name = fichier.nomFichier ?? fichier.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (canDelete && onDeleteRequested != null)
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () {
                                Navigator.pop(ctx);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  onDeleteRequested!();
                                });
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        child: _isImage
                            ? InteractiveViewer(
                                minScale: 0.8,
                                maxScale: 4,
                                child: Image.network(
                                  fichier.lienFichier,
                                  headers: imageHeaders,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 56,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      fichier.isVideo
                                          ? Icons.play_circle_outline
                                          : Icons.insert_drive_file_outlined,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: fichier.isVideo
                  ? ColoredBox(
                      color: Colors.black12,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final dpr = MediaQuery.devicePixelRatioOf(context);
                        final cachePx =
                            (160 * dpr).round().clamp(128, 512);
                        return Image.network(
                          fichier.lienFichier,
                          headers: imageHeaders,
                          fit: BoxFit.cover,
                          cacheWidth: cachePx,
                          cacheHeight: cachePx,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(Icons.broken_image_outlined, size: 48),
                              ),
                          loadingBuilder: (c, w, p) {
                            if (p == null) return w;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderChoiceTile extends StatelessWidget {
  const _FolderChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderGridTile extends StatelessWidget {
  const _FolderGridTile({
    required this.folder,
    required this.onTap,
    this.onDelete,
  });

  final String folder;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = folder.split('/').last;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') onDelete!();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer le dossier'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadActionTile extends StatelessWidget {
  const _UploadActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AromaColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modale « nouveau dossier » alignée sur le thème Aroma (M3, zinc).
class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog({this.parentFolder});

  final String? parentFolder;

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  static final RegExp _allowedSegmentChars = RegExp(r'^[A-Za-z0-9 _.-]+$');
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty && _folderValidationError == null;

  String get _normalizedParent {
    final raw = widget.parentFolder?.trim() ?? '';
    return raw.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  String get _finalFolderPath {
    final name = _controller.text.trim();
    if (_normalizedParent.isEmpty) return name;
    return '$_normalizedParent/$name';
  }

  String? get _folderValidationError {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parts = raw.replaceAll('\\', '/').split('/').where((p) => p.trim().isNotEmpty);
    for (final seg in parts) {
      final s = seg.trim();
      if (s == '.' || s == '..') return 'Nom de dossier invalide.';
      if (s.length > 120) return 'Nom de dossier trop long.';
      if (!_allowedSegmentChars.hasMatch(s)) {
        return 'Caracteres non autorises (A-Z, 0-9, espace, _, ., -).';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: AromaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xCC_E4E4E7)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AromaColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.create_new_folder_outlined,
                            size: 26,
                            color: AromaColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouveau dossier',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.35,
                                color: AromaColors.zinc900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pour un sous-dossier, utilisez / '
                              '(ex. Campagnes/2026).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AromaColors.zinc500,
                                height: 1.35,
                              ),
                            ),
                            if (_normalizedParent.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Création dans : $_normalizedParent',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AromaColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_canSubmit) {
                        Navigator.pop(context, _finalFolderPath);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Nom du dossier',
                      hintText: _normalizedParent.isEmpty
                          ? 'Campagnes/2026'
                          : 'Ex: Q1',
                      prefixIcon: const Icon(Icons.folder_outlined, size: 22),
                      errorText: _folderValidationError,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AromaColors.zinc900,
                            side: const BorderSide(color: AromaColors.zinc200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _canSubmit
                              ? () => Navigator.pop(
                                    context,
                                    _finalFolderPath,
                                  )
                              : null,
                          child: const Text('Créer'),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
