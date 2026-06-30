import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/intervention_rapport_draft.dart';
import '../../theme/aroma_theme.dart';

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

/// Prise de photo directe pour un critère du rapport d’intervention.
class RapportPhotoSlotWidget extends StatelessWidget {
  const RapportPhotoSlotWidget({
    super.key,
    required this.label,
    required this.slot,
    required this.onChanged,
    this.gridTile = false,
  });

  final String label;
  final RapportPhotoSlot slot;
  final ValueChanged<RapportPhotoSlot> onChanged;
  final bool gridTile;

  static final _picker = ImagePicker();

  Future<void> _capture(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file == null) return;
    onChanged(RapportPhotoSlot(localPath: file.path));
  }

  void _remove() {
    onChanged(RapportPhotoSlot());
  }

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

  @override
  Widget build(BuildContext context) {
    if (gridTile) return _buildGridTile(context);
    return _buildListTile(context);
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
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
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
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        preview,
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _GridActionChip(
                            icon: Icons.close_rounded,
                            color: const Color(0xFFDC2626),
                            onTap: _remove,
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: _GridActionChip(
                            icon: Icons.camera_alt_outlined,
                            color: const Color(0xFF0284C7),
                            onTap: () => _capture(context),
                          ),
                        ),
                      ],
                    )
                  : Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _capture(context),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AromaColors.zinc200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 28,
                                color: Color(0xFF0284C7),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  fontSize: 12,
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
          ),
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
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AromaColors.zinc800,
                  height: 1.35,
                ),
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
                    onPressed: () => _capture(context),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Reprendre'),
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
                onTap: () => _capture(context),
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
                        Icons.camera_alt_rounded,
                        size: 36,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Prendre une photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
