import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/discipline_rh.dart';
import '../../models/tache.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/document_urls.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import 'rh_discipline_card.dart';
import 'rh_ui.dart';

class RhDisciplineTab extends StatefulWidget {
  const RhDisciplineTab({
    super.key,
    this.collaborateurId,
    this.showCollaborateurNames = false,
  });

  final String? collaborateurId;
  final bool showCollaborateurNames;

  @override
  State<RhDisciplineTab> createState() => _RhDisciplineTabState();
}

class _RhDisciplineTabState extends State<RhDisciplineTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<DisciplineRh> _rows = [];
  List<CollaborateurLite> _collaborateurs = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.api.listDisciplinesRhParsed(),
        if (widget.showCollaborateurNames)
          auth.api.listCollaborateursLite()
        else
          Future.value(<CollaborateurLite>[]),
      ]);
      if (!mounted) return;
      var rows = results[0] as List<DisciplineRh>;
      if (widget.collaborateurId != null) {
        rows = rows
            .where((d) => d.idCollaborateur == widget.collaborateurId)
            .toList();
      }
      setState(() {
        _rows = rows;
        _collaborateurs = results[1] as List<CollaborateurLite>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _collabName(String id) {
    for (final c in _collaborateurs) {
      if (c.id == id) return c.fullName;
    }
    return null;
  }

  void _openDetail(DisciplineRh d) {
    final auth = context.read<AuthProvider>();
    final canRespond = !auth.isPrivilegedStaff &&
        auth.collaborateurId == d.idCollaborateur;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DisciplineDetailSheet(
        discipline: d,
        collaborateurName: _collabName(d.idCollaborateur),
        canRespond: canRespond,
        onUpdated: _reload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RhEmptyState(
        title: _error!,
        icon: Icons.error_outline_rounded,
      );
    }
    if (_rows.isEmpty) {
      return const RhEmptyState(
        title: 'Aucun dossier discipline',
        subtitle: 'Les enregistrements disciplinaires apparaîtront ici.',
        icon: Icons.gavel_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = _rows[i];
          return RhDisciplineCard(
            discipline: d,
            collaborateurName: widget.showCollaborateurNames
                ? _collabName(d.idCollaborateur)
                : null,
            onTap: () => _openDetail(d),
          );
        },
      ),
    );
  }
}

class _DisciplineDetailSheet extends StatefulWidget {
  const _DisciplineDetailSheet({
    required this.discipline,
    required this.canRespond,
    required this.onUpdated,
    this.collaborateurName,
  });

  final DisciplineRh discipline;
  final String? collaborateurName;
  final bool canRespond;
  final Future<void> Function() onUpdated;

  @override
  State<_DisciplineDetailSheet> createState() => _DisciplineDetailSheetState();
}

class _DisciplineDetailSheetState extends State<_DisciplineDetailSheet> {
  late final TextEditingController _justification;
  bool _submitting = false;
  String? _pendingFilePath;

  @override
  void initState() {
    super.initState();
    _justification = TextEditingController(
      text: widget.discipline.justification ?? '',
    );
  }

  @override
  void dispose() {
    _justification.dispose();
    super.dispose();
  }

  Future<void> _openDocument(String path) async {
    final url = documentOpenUrl(path);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le document.')),
      );
    }
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles();
    if (picked != null && picked.files.single.path != null) {
      setState(() => _pendingFilePath = picked.files.single.path);
    }
  }

  Future<void> _submitResponse() async {
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final body = <String, dynamic>{
        'justification': _justification.text.trim(),
      };
      if (_pendingFilePath != null) {
        final uploaded =
            await auth.api.uploadDisciplineDocuments([_pendingFilePath!]);
        final docs = [...widget.discipline.documents, ...uploaded];
        body['documents'] = docs;
      }

      await auth.api.patchDisciplineRh(widget.discipline.id, body);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse enregistrée.')),
      );
      await widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.discipline;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AromaColors.zinc200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RhUi.gradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          RhUi.typeDisciplineIcon(d.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelTypeDiscipline(d.type),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.collaborateurName != null)
                              Text(
                                widget.collaborateurName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AromaColors.zinc500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      RhDisciplineStatusBadge(statut: d.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: 'Informations',
                    rows: [
                      ('Date', formatDateFr(d.date)),
                      ('Motif', d.motif),
                      ('Type explication', disciplineTypeExplicationLabel(d)),
                      (
                        'Impact paie',
                        d.impactPaie ? 'Oui' : 'Non',
                      ),
                    ],
                  ),
                  if (d.descriptionProbleme != null &&
                      d.descriptionProbleme!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Description du problème',
                      rows: [
                        ('', d.descriptionProbleme),
                      ],
                    ),
                  ],
                  if (d.justification != null &&
                      d.justification!.trim().isNotEmpty &&
                      !widget.canRespond) ...[
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Justification collaborateur',
                      rows: [
                        ('', d.justification),
                      ],
                    ),
                  ],
                  if (d.documents.isNotEmpty ||
                      d.lettreDocumentPath != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Documents',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (d.lettreDocumentPath != null)
                      _DocTile(
                        label: d.lettreDocumentName ?? 'Lettre officielle',
                        onTap: () => _openDocument(d.lettreDocumentPath!),
                      ),
                    ...d.documents.map(
                      (doc) => _DocTile(
                        label: '${doc['name'] ?? doc['fileName'] ?? 'Document'}',
                        onTap: () {
                          final path = '${doc['path'] ?? doc['url'] ?? ''}';
                          if (path.isNotEmpty) _openDocument(path);
                        },
                      ),
                    ),
                  ],
                  if (widget.canRespond) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Votre réponse',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _justification,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Justification',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickFile,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        _pendingFilePath != null
                            ? 'Justificatif sélectionné'
                            : 'Joindre un justificatif (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _submitting ? null : _submitResponse,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer ma réponse'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AromaColors.zinc900,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((r) {
            final value = (r.$2 == null || r.$2!.trim().isEmpty) ? '—' : r.$2!;
            if (r.$1.isEmpty) {
              return Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AromaColors.zinc800,
                  height: 1.4,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AromaColors.zinc900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 18, color: RhUi.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, size: 16, color: AromaColors.zinc500),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
