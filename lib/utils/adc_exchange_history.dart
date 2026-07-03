import 'dart:convert';

import '../models/intervention.dart';

class AdcExchangeEntry {
  AdcExchangeEntry({
    required this.id,
    required this.dateIso,
    required this.agent,
    required this.moyen,
    required this.resume,
    required this.contactLabel,
    this.messageCorps,
    this.notesAppel,
    this.ressenti,
  });

  final String id;
  final String dateIso;
  final String agent;
  final String moyen;
  final String resume;
  final String contactLabel;
  final String? messageCorps;
  final String? notesAppel;
  final String? ressenti;

  String get dateAffiche {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(dateIso);
    if (m != null) {
      return '${m.group(3)}/${m.group(2)}/${m.group(1)}';
    }
    return dateIso;
  }
}

String? _normalizeAdcRessenti(dynamic v) {
  if (v == null) return null;
  if (v is num) {
    final n = v.round();
    if (n >= 0 && n <= 10) return '$n/10';
    return null;
  }
  final s = '$v'.trim();
  if (s.isEmpty) return null;
  final n = int.tryParse(s);
  if (n != null && n >= 0 && n <= 10) return '$n/10';
  return s;
}

({String message, String? ressenti}) _parsePhoneRelancePayload(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return (message: '', ressenti: null);
  if (t.startsWith('{')) {
    try {
      final o = jsonDecode(t) as Map<String, dynamic>;
      final message = (o['message'] as String? ?? '').trim();
      final ressenti = _normalizeAdcRessenti(o['ressenti']);
      return (message: message, ressenti: ressenti);
    } catch (_) {
      /* texte brut */
    }
  }
  return (message: t, ressenti: null);
}

String _truncateHist(String text, int max) {
  final t = text.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max)}…';
}

String _traceMoyen(String? canal) {
  final c = (canal ?? '').trim();
  if (c == 'WhatsApp' || c == 'Téléphone' || c == 'Mail') return c;
  return 'Mail';
}

String _traceDateIso(AdcActionTrace e) {
  final date = (e.date ?? '').trim();
  if (date.isEmpty) return DateTime.now().toUtc().toIso8601String();
  final heure = (e.heure ?? '').trim();
  final iso = heure.isNotEmpty ? '${date}T$heure:00' : '${date}T12:00:00';
  final parsed = DateTime.tryParse(iso);
  if (parsed != null) return parsed.toUtc().toIso8601String();
  return iso;
}

List<AdcExchangeEntry> _actionTraceToHistorique(
  List<AdcActionTrace> trace,
  String agentFallback,
) {
  if (trace.isEmpty) return [];
  return trace.asMap().entries.map((row) {
    final i = row.key;
    final e = row.value;
    final moyen = _traceMoyen(e.canal);
    String? notesAppel;
    String? ressenti = _normalizeAdcRessenti(e.ressenti);

    if (moyen == 'Téléphone') {
      final rawMessage = (e.message ?? '').trim();
      if (rawMessage.startsWith('{')) {
        final parsed = _parsePhoneRelancePayload(rawMessage);
        notesAppel = parsed.message.isNotEmpty ? parsed.message : null;
        ressenti ??= parsed.ressenti;
      } else if (rawMessage.contains('\n\n')) {
        final parts = rawMessage
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          notesAppel = parts.sublist(1).join('\n\n');
        } else {
          notesAppel = rawMessage;
        }
      } else if (rawMessage.isNotEmpty) {
        notesAppel = rawMessage;
      }
    }

    final draft = AdcExchangeEntry(
      id: 'trace-$i-${e.date ?? ''}-${e.heure ?? ''}',
      dateIso: _traceDateIso(e),
      agent: (e.auteur ?? '').trim().isNotEmpty ? e.auteur!.trim() : agentFallback,
      moyen: moyen,
      resume: '',
      contactLabel: (e.contact ?? '').trim().isNotEmpty ? e.contact!.trim() : '—',
      messageCorps: e.message,
      notesAppel: notesAppel,
      ressenti: ressenti,
    );
    return AdcExchangeEntry(
      id: draft.id,
      dateIso: draft.dateIso,
      agent: draft.agent,
      moyen: draft.moyen,
      resume: adcExchangeResumeText(draft),
      contactLabel: draft.contactLabel,
      messageCorps: draft.messageCorps,
      notesAppel: draft.notesAppel,
      ressenti: draft.ressenti,
    );
  }).toList();
}

List<AdcExchangeEntry> buildAdcExchangeHistory({
  required List<AdcActionTrace> trace,
  String agentFallback = '—',
  String? relanceTelephoneMessage,
  String? adcRessenti,
}) {
  var entries = _actionTraceToHistorique(trace, agentFallback);

  final relJson = (relanceTelephoneMessage ?? '').trim();
  if (relJson.isNotEmpty) {
    final parsed = _parsePhoneRelancePayload(relJson);
    final phones = entries.where((e) => e.moyen == 'Téléphone').toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    if (phones.isNotEmpty) {
      final latestId = phones.first.id;
      entries = entries.map((e) {
        if (e.id != latestId) return e;
        return AdcExchangeEntry(
          id: e.id,
          dateIso: e.dateIso,
          agent: e.agent,
          moyen: e.moyen,
          resume: e.resume,
          contactLabel: e.contactLabel,
          messageCorps: e.messageCorps,
          notesAppel: (e.notesAppel ?? '').trim().isNotEmpty
              ? e.notesAppel
              : (parsed.message.isNotEmpty ? parsed.message : e.notesAppel),
          ressenti: e.ressenti ?? parsed.ressenti ?? e.ressenti,
        );
      }).toList();
    }
  }

  final rv = _normalizeAdcRessenti(adcRessenti);
  if (rv != null) {
    final phones = entries.where((e) => e.moyen == 'Téléphone').toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    if (phones.isNotEmpty && (phones.first.ressenti ?? '').isEmpty) {
      final latestId = phones.first.id;
      entries = entries.map((e) {
        if (e.id != latestId) return e;
        return AdcExchangeEntry(
          id: e.id,
          dateIso: e.dateIso,
          agent: e.agent,
          moyen: e.moyen,
          resume: e.resume,
          contactLabel: e.contactLabel,
          messageCorps: e.messageCorps,
          notesAppel: e.notesAppel,
          ressenti: rv,
        );
      }).toList();
    }
  }

  entries.sort((a, b) => b.dateIso.compareTo(a.dateIso));
  return entries
      .map(
        (e) => AdcExchangeEntry(
          id: e.id,
          dateIso: e.dateIso,
          agent: e.agent,
          moyen: e.moyen,
          resume: adcExchangeResumeText(e),
          contactLabel: e.contactLabel,
          messageCorps: e.messageCorps,
          notesAppel: e.notesAppel,
          ressenti: e.ressenti,
        ),
      )
      .toList();
}

/// Texte lisible pour affichage (évite le JSON brut des relances téléphone).
String adcExchangeDisplayText(AdcExchangeEntry e) {
  final notes = (e.notesAppel ?? '').trim();
  if (notes.isNotEmpty) return notes;
  final raw = (e.messageCorps ?? e.resume).trim();
  if (raw.isEmpty) return '—';
  if (raw.startsWith('{')) {
    final parsed = _parsePhoneRelancePayload(raw);
    if (parsed.message.isNotEmpty) return parsed.message;
  }
  return raw;
}

String adcExchangeResumeText(AdcExchangeEntry e) {
  final display = adcExchangeDisplayText(e);
  if (display != '—') return _truncateHist(display, 160);
  final resume = e.resume.trim();
  if (resume.isNotEmpty && !resume.startsWith('{')) return resume;
  return '—';
}
