import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/intervention_rapport_draft.dart';
import '../../theme/aroma_theme.dart';
import '../modern_bottom_sheet.dart';

/// Liste verticale de slots photo compacts (ligne par critère).
class RapportPhotoCompactList extends StatelessWidget {
  const RapportPhotoCompactList({
    super.key,
    required this.children,
    this.gap = 6,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}

/// Grille 2 colonnes pour les slots photo du rapport.
class RapportPhotoSlotsGrid extends StatelessWidget {
  const RapportPhotoSlotsGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final hasRight = i + 1 < children.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: spacing),
            Expanded(
              child: hasRight ? children[i + 1] : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }
    return Column(children: rows);
  }
}

/// Prise de photo pour un critère du rapport d’intervention.
class RapportPhotoSlotWidget extends StatefulWidget {
  const RapportPhotoSlotWidget({
    super.key,
    required this.label,
    required this.slot,
    required this.onChanged,
    this.gridTile = false,
    this.compact = false,
    this.uploading = false,
  });

  final String label;
  final RapportPhotoSlot slot;
  final ValueChanged<RapportPhotoSlot> onChanged;
  final bool gridTile;
  final bool compact;
  final bool uploading;

  @override
  State<RapportPhotoSlotWidget> createState() => _RapportPhotoSlotWidgetState();
}

class _RapportPhotoSlotWidgetState extends State<RapportPhotoSlotWidget> {
  static final _picker = ImagePicker();

  bool _observationExpanded = false;

  RapportPhotoSlot get slot => widget.slot;

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;
    widget.onChanged(slot.copyWith(localPath: file.path));
  }

  Future<void> _showPhotoSourceSheet(BuildContext context) async {
    await showModernActionSheet(
      context: context,
      title: 'Ajouter une photo',
      theme: ModernSheetThemes.interventions,
      actions: [
        ModernSheetActionTile(
          icon: Icons.photo_camera_outlined,
          title: 'Prendre une photo',
          subtitle: 'Ouvre l’appareil photo',
          theme: ModernSheetThemes.interventions,
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
        ModernSheetActionTile(
          icon: Icons.photo_library_outlined,
          title: 'Choisir depuis la galerie',
          subtitle: 'Sélectionner une image existante',
          theme: ModernSheetThemes.interventions,
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  void _remove() {
    widget.onChanged(RapportPhotoSlot());
    setState(() => _observationExpanded = false);
  }

  void _toggleObservation() {
    setState(() => _observationExpanded = !_observationExpanded);
  }

  void _setObservation(String value) {
    widget.onChanged(slot.copyWith(observation: value));
  }

  bool get _isUploaded =>
      slot.galerieId != null && slot.galerieId!.isNotEmpty;

  Widget? _previewImage() {
    final local = slot.localPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      return Image.file(File(local), fit: BoxFit.cover);
    }
    final url = slot.galerieUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return null;
  }

  Widget _observationToggle({double size = 18}) {
    final hasObservation = slot.hasObservation;
    return IconButton(
      onPressed: widget.uploading ? null : _toggleObservation,
      tooltip: _observationExpanded ? 'Masquer l’observation' : 'Observation',
      icon: Icon(
        hasObservation
            ? Icons.comment_rounded
            : Icons.comment_outlined,
        size: size,
        color: hasObservation
            ? const Color(0xFF0284C7)
            : (_observationExpanded
                ? const Color(0xFF0284C7)
                : AromaColors.zinc500),
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: size + 10,
        minHeight: size + 10,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _observationField({bool dense = false}) {
    return _PhotoObservationField(
      key: ValueKey('${widget.label}_obs'),
      value: slot.observation ?? '',
      dense: dense,
      onChanged: _setObservation,
    );
  }

  Widget _observationPanel({bool dense = false}) {
    if (!_observationExpanded) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: dense ? 4 : 8),
      child: _observationField(dense: dense),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompactRow(context);
    if (widget.gridTile) return _buildGridTile(context);
    return _buildListTile(context);
  }

  Widget _buildCompactRow(BuildContext context) {
    final preview = _previewImage();
    final hasPhoto = preview != null;
    const accent = Color(0xFF0EA5E9);
    const done = Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: hasPhoto ? Colors.white : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasPhoto
                    ? accent.withValues(alpha: 0.45)
                    : AromaColors.zinc200,
              ),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.uploading
                        ? null
                        : () => _showPhotoSourceSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: hasPhoto
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  preview,
                                  if (widget.uploading)
                                    const ColoredBox(
                                      color: Colors.black26,
                                      child: Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AromaColors.zinc200,
                                    strokeAlign:
                                        BorderSide.strokeAlignInside,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 20,
                                  color: accent,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.uploading
                        ? null
                        : () => _showPhotoSourceSheet(context),
                    child: Text(
                      widget.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            hasPhoto ? AromaColors.zinc900 : AromaColors.zinc800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                _observationToggle(),
                if (widget.uploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_isUploaded)
                  const Icon(Icons.cloud_done_rounded, size: 18, color: done)
                else if (hasPhoto)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: done,
                      ),
                      IconButton(
                        onPressed: _remove,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: AromaColors.zinc500,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showPhotoSourceSheet(context),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          size: 22,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _observationPanel(dense: true),
      ],
    );
  }

  Widget _buildGridTile(BuildContext context) {
    final preview = _previewImage();
    final hasPhoto = preview != null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto ? const Color(0xFF0EA5E9) : AromaColors.zinc200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc800,
                        height: 1.3,
                      ),
                    ),
                  ),
                  _observationToggle(size: 16),
                ],
              ),
            ),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        preview,
                        if (widget.uploading)
                          const ColoredBox(
                            color: Colors.black26,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (_isUploaded && !widget.uploading)
                          const Positioned(
                            top: 6,
                            left: 6,
                            child: Icon(
                              Icons.cloud_done_outlined,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _GridActionChip(
                            icon: Icons.close_rounded,
                            color: const Color(0xFFDC2626),
                            onTap: _remove,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: _GridActionChip(
                            icon: Icons.camera_alt_outlined,
                            color: const Color(0xFF0284C7),
                            onTap: () => _showPhotoSourceSheet(context),
                          ),
                        ),
                      ],
                    )
                  : Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _showPhotoSourceSheet(context),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 24,
                              color: Color(0xFF0284C7),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Photo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          _observationPanel(),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    final preview = _previewImage();
    final hasPhoto = preview != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AromaColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto ? const Color(0xFF0EA5E9) : AromaColors.zinc200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc800,
                        height: 1.35,
                      ),
                    ),
                  ),
                  _observationToggle(size: 20),
                ],
              ),
            ),
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: preview,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPhotoSourceSheet(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Remplacer'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _remove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFDC2626),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ] else
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _showPhotoSourceSheet(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AromaColors.zinc200),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 36,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Appareil photo ou galerie',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _observationPanel(),
        ],
      ),
    );
  }
}

class _PhotoObservationField extends StatefulWidget {
  const _PhotoObservationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool dense;

  @override
  State<_PhotoObservationField> createState() => _PhotoObservationFieldState();
}

class _PhotoObservationFieldState extends State<_PhotoObservationField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_PhotoObservationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: widget.dense ? 2 : 3,
      minLines: 1,
      style: TextStyle(fontSize: widget.dense ? 12 : 13),
      decoration: InputDecoration(
        labelText: 'Observation',
        hintText: 'Optionnel',
        isDense: widget.dense,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: widget.dense ? 8 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AromaColors.zinc200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AromaColors.zinc200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0284C7)),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _GridActionChip extends StatelessWidget {
  const _GridActionChip({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
