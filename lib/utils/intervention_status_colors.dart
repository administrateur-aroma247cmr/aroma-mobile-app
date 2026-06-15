import 'package:flutter/material.dart';

class StatusBadgeColors {
  const StatusBadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

/// Couleurs par état d'intervention — aligné CRM web (`ETAT_COLORS`).
abstract final class InterventionStatusColors {
  static const _default = StatusBadgeColors(
    background: Color(0xFFF4F4F5),
    foreground: Color(0xFF52525B),
    border: Color(0xFFE4E4E7),
  );

  static const _map = <String, StatusBadgeColors>{
    'Planifié': StatusBadgeColors(
      background: Color(0xFFE0F2FE),
      foreground: Color(0xFF075985),
      border: Color(0xFFBAE6FD),
    ),
    'Démarré': StatusBadgeColors(
      background: Color(0xFFFEF3C7),
      foreground: Color(0xFF92400E),
      border: Color(0xFFFDE68A),
    ),
    'Traité': StatusBadgeColors(
      background: Color(0xFFD1FAE5),
      foreground: Color(0xFF065F46),
      border: Color(0xFFA7F3D0),
    ),
    'Effectué': StatusBadgeColors(
      background: Color(0xFFD1FAE5),
      foreground: Color(0xFF065F46),
      border: Color(0xFFA7F3D0),
    ),
    "En attente rapport d'intervention": StatusBadgeColors(
      background: Color(0xFFFFEDD5),
      foreground: Color(0xFF9A3412),
      border: Color(0xFFFED7AA),
    ),
    "Rapport d'intervention": StatusBadgeColors(
      background: Color(0xFFDBEAFE),
      foreground: Color(0xFF1E40AF),
      border: Color(0xFFBFDBFE),
    ),
    'Rapport envoyé': StatusBadgeColors(
      background: Color(0xFFDBEAFE),
      foreground: Color(0xFF1E40AF),
      border: Color(0xFFBFDBFE),
    ),
    'Clos': StatusBadgeColors(
      background: Color(0xFFF4F4F5),
      foreground: Color(0xFF3F3F46),
      border: Color(0xFFE4E4E7),
    ),
    'En cours': StatusBadgeColors(
      background: Color(0xFFEDE9FE),
      foreground: Color(0xFF5B21B6),
      border: Color(0xFFDDD6FE),
    ),
  };

  static StatusBadgeColors forEtat(String? etat) {
    final v = (etat ?? '').trim();
    if (v.isEmpty) return _default;
    return _map[v] ?? _default;
  }
}

/// Couleurs statut ADC — aligné `ADCInteractionsView`.
abstract final class AdcStatutColors {
  static const _default = StatusBadgeColors(
    background: Color(0xFFF4F4F5),
    foreground: Color(0xFF3F3F46),
    border: Color(0xFFE4E4E7),
  );

  static StatusBadgeColors forStatut(String? statut) {
    switch ((statut ?? '').trim()) {
      case 'répondu':
        return const StatusBadgeColors(
          background: Color(0x1A10B981),
          foreground: Color(0xFF047857),
          border: Color(0x99A7F3D0),
        );
      case 'en_attente':
        return const StatusBadgeColors(
          background: Color(0x1AF59E0B),
          foreground: Color(0xFFB45309),
          border: Color(0x99FDE68A),
        );
      case 'non_répondu':
        return const StatusBadgeColors(
          background: Color(0x1AEF4444),
          foreground: Color(0xFFB91C1C),
          border: Color(0x99FECACA),
        );
      case 'reporté':
        return const StatusBadgeColors(
          background: Color(0x1A3B82F6),
          foreground: Color(0xFF1D4ED8),
          border: Color(0x99BFDBFE),
        );
      default:
        return _default;
    }
  }

  static String label(String? statut) {
    switch ((statut ?? '').trim()) {
      case 'répondu':
        return 'Répondu';
      case 'non_répondu':
        return 'Non répondu';
      case 'en_attente':
        return 'En attente';
      case 'reporté':
        return 'Reporté';
      default:
        return (statut ?? '').trim().isEmpty ? '—' : statut!.trim();
    }
  }
}
