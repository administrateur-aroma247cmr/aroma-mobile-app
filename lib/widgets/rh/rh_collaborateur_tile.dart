import 'package:flutter/material.dart';

import '../../models/tache.dart';
import '../../theme/aroma_theme.dart';
import 'rh_ui.dart';

class RhCollaborateurTile extends StatelessWidget {
  const RhCollaborateurTile({
    super.key,
    required this.collaborateur,
    required this.onTap,
  });

  final CollaborateurLite collaborateur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AromaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: RhUi.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    RhUi.initials(collaborateur.fullName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    collaborateur.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AromaColors.zinc900,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AromaColors.zinc500.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
