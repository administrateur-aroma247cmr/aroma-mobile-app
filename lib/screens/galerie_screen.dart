import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/galerie_fichier.dart';
import '../providers/auth_provider.dart';
import '../services/aroma_api.dart';

class GalerieScreen extends StatefulWidget {
  const GalerieScreen({super.key, this.embedded = false});

  /// Dans [MainShell] : pas de barre propre (AppBar / déconnexion gérés au-dessus).
  final bool embedded;

  @override
  State<GalerieScreen> createState() => GalerieScreenState();
}

class GalerieScreenState extends State<GalerieScreen> {
  final _picker = ImagePicker();
  Future<List<GalerieFichier>>? _future;
  bool _uploading = false;

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
  }

  /// Utilisé par [MainShell] (bouton actualiser de l’AppBar).
  void reload() => _reload();

  Future<void> _uploadPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    final api = context.read<AuthProvider>().api;
    setState(() => _uploading = true);
    try {
      await api.uploadGalerie(paths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${paths.length} fichier(s) envoyé(s).')),
        );
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l’envoi : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    final x = await _picker.pickVideo(source: source);
    if (x == null) return;
    await _uploadPaths([x.path]);
  }

  Future<void> _pickMultipleMedia() async {
    final list = await _picker.pickMultipleMedia();
    if (list.isEmpty) return;
    await _uploadPaths(list.map((e) => e.path).toList());
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
    await _uploadPaths(paths);
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Filmer une vidéo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Vidéo depuis l’appareil'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined),
                title: const Text('Photos / médias (plusieurs)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMultipleMedia();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Fichiers…'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () =>
                      context.read<AuthProvider>().logout(),
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
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucun fichier pour l’instant.\n'
                          'Ajoutez une photo, une vidéo ou un fichier.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final g = items[i];
                    return _GalerieTile(fichier: g);
                  },
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
        onPressed: _uploading ? null : _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _GalerieTile extends StatelessWidget {
  const _GalerieTile({required this.fichier});

  final GalerieFichier fichier;

  @override
  Widget build(BuildContext context) {
    final name = fichier.nomFichier ?? fichier.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              content: SelectableText(fichier.lienFichier),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ],
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
                  : Image.network(
                      fichier.lienFichier,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                      loadingBuilder: (c, w, p) {
                        if (p == null) return w;
                        return const Center(child: CircularProgressIndicator());
                      },
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
    );
  }
}
