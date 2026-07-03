import 'dart:convert';

import '../models/contact_client.dart';
import '../models/intervention.dart';
import 'adc_exchange_history.dart';

final adcStatutOptions = <({String value, String label})>[
  (value: 'répondu', label: 'Répondu'),
  (value: 'non_répondu', label: 'Non répondu'),
  (value: 'en_attente', label: 'En attente'),
  (value: 'reporté', label: 'Reporté'),
];

final adcRessentiOptions = <({String value, String label})>[
  (value: '', label: '— Non renseigné —'),
  for (var i = 0; i <= 10; i++) (value: '$i', label: '$i'),
];

String ressentiToSelectValue(dynamic r) {
  if (r == null) return '';
  final s = '$r'.trim();
  if (s.isEmpty) return '';
  final n = int.tryParse(s);
  if (n != null && n >= 0 && n <= 10) return '$n';
  return '';
}

bool isAdcFicheHistorique(String? datePlanifiee) {
  final raw = (datePlanifiee ?? '').trim();
  if (raw.isEmpty) return false;
  final planned = DateTime.tryParse(raw);
  if (planned == null) return false;
  final now = DateTime.now();
  return planned.year * 12 + planned.month < now.year * 12 + now.month;
}

String toPhoneRelanceJson({
  required String message,
  String? ressenti,
  bool? rappeler,
}) {
  if ((ressenti == null || ressenti.isEmpty) && rappeler == null) {
    return message;
  }
  return jsonEncode({
    'message': message,
    'ressenti': ressenti ?? '',
    if (rappeler != null) 'rappeler': rappeler,
  });
}

String truncateAdcHist(String text, int max) {
  final t = text.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max)}…';
}

String digitsOnlyPhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

List<Map<String, dynamic>> historiqueToActionTrace(List<AdcExchangeEntry> entries) {
  return entries.map((e) {
    final parsed = DateTime.tryParse(e.dateIso);
    final date = parsed != null
        ? '${parsed.year.toString().padLeft(4, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.day.toString().padLeft(2, '0')}'
        : e.dateIso.length >= 10
            ? e.dateIso.substring(0, 10)
            : e.dateIso;
    final heure = parsed != null
        ? '${parsed.hour.toString().padLeft(2, '0')}:'
            '${parsed.minute.toString().padLeft(2, '0')}'
        : null;

    final base = <String, dynamic>{
      'date': date,
      if (heure != null) 'heure': heure,
      'canal': e.moyen,
      'contact': e.contactLabel,
      'auteur': e.agent,
    };

    if (e.moyen == 'Téléphone') {
      final notes = (e.notesAppel ?? e.resume).trim();
      final ressentiRaw = (e.ressenti ?? '').replaceAll('/10', '').trim();
      final message = ressentiRaw.isNotEmpty
          ? toPhoneRelanceJson(message: notes, ressenti: ressentiRaw)
          : notes.isNotEmpty
              ? notes
              : e.resume;
      return {
        ...base,
        'message': message,
        if (notes.isNotEmpty) 'description': notes,
        if (ressentiRaw.isNotEmpty) 'ressenti': ressentiRaw,
      };
    }

    return {
      ...base,
      'message': (e.messageCorps ?? e.resume).trim(),
    };
  }).toList();
}

AdcExchangeEntry newAdcExchangeEntry({
  required String agent,
  required String moyen,
  required String resume,
  required String contactLabel,
  String? dateIso,
  String? messageCorps,
  String? notesAppel,
  String? ressenti,
}) {
  return AdcExchangeEntry(
    id: '${DateTime.now().microsecondsSinceEpoch}-${moyen.hashCode}',
    dateIso: dateIso ?? DateTime.now().toUtc().toIso8601String(),
    agent: agent,
    moyen: moyen,
    resume: resume,
    contactLabel: contactLabel,
    messageCorps: messageCorps,
    notesAppel: notesAppel,
    ressenti: ressenti,
  );
}

String initialContactConcerneId(ExperienceAdcDetail detail) {
  final id = (detail.idContact ?? '').trim();
  if (id.isNotEmpty && detail.contacts.any((c) => c.id == id)) return id;
  return detail.contacts.isNotEmpty ? detail.contacts.first.id : '';
}

AdcContact adcContactFromClient(ContactClient c) {
  return AdcContact(
    id: c.id,
    nom: c.nom,
    prenom: c.prenom,
    poste: c.poste,
    telephone: c.telephone,
    email: c.email,
    typeContact: c.typeContact,
  );
}

/// Corps PATCH ADC — aligné `handleEnregistrer` CRM web.
Map<String, dynamic> buildAdcPatchBody({
  required String? contactConcerneId,
  required String adcStatut,
  required String adcRessenti,
  required String observations,
  required List<AdcExchangeEntry> exchangeHistory,
  required String lastSentMailMessage,
  required String lastSentWhatsappMessage,
  required String lastSentPhoneMessage,
  required bool isFicheHistorique,
  required String manualDateAppel,
}) {
  final tracePayload = historiqueToActionTrace(exchangeHistory);
  final phoneEntries =
      exchangeHistory.where((e) => e.moyen == 'Téléphone').toList();
  var statutToSave = adcStatut;
  String? dateAppel;
  final hasRessenti = adcRessenti.isNotEmpty;
  final hasHistorique = exchangeHistory.isNotEmpty;
  final ressentiToSave = statutToSave == 'non_répondu' ? '' : adcRessenti;

  if ((phoneEntries.isNotEmpty || (hasRessenti && hasHistorique)) &&
      statutToSave != 'non_répondu' &&
      statutToSave != 'reporté') {
    final s = statutToSave.trim().toLowerCase();
    if (s == 'en_attente' || s == 'planifié' || s == 'planifie') {
      statutToSave = 'répondu';
    }
  }
  if (phoneEntries.isNotEmpty) {
    phoneEntries.sort((a, b) => b.dateIso.compareTo(a.dateIso));
    dateAppel = phoneEntries.first.dateIso;
  }
  if (isFicheHistorique && manualDateAppel.trim().isNotEmpty) {
    dateAppel = '${manualDateAppel.trim()}T12:00:00.000Z';
  }
  if (statutToSave == 'non_répondu' && hasHistorique && dateAppel == null) {
    final sorted = List<AdcExchangeEntry>.from(exchangeHistory)
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    dateAppel = sorted.first.dateIso;
  }

  return {
    'id_contact': (contactConcerneId ?? '').trim().isNotEmpty
        ? contactConcerneId
        : null,
    'statut': statutToSave,
    'ressenti': ressentiToSave,
    'commentaire': observations.trim().isNotEmpty ? observations.trim() : null,
    if (dateAppel != null) 'date_appel': dateAppel,
    if (lastSentWhatsappMessage.trim().isNotEmpty)
      'relance_whatsapp_message': lastSentWhatsappMessage,
    if (lastSentMailMessage.trim().isNotEmpty)
      'relance_mail_message': lastSentMailMessage,
    if (lastSentPhoneMessage.trim().isNotEmpty)
      'relance_telephone_message': lastSentPhoneMessage,
    if (tracePayload.isNotEmpty) 'actions_trace': tracePayload,
  };
}

bool isAdcStatutRepondu(String? statut) =>
    (statut ?? '').trim() == 'répondu';
