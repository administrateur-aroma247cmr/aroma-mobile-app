import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/adc_exchange_history.dart';
import '../utils/adc_form_logic.dart';
import '../utils/format_utils.dart';
import '../utils/intervention_evaluation_constants.dart';
import '../widgets/interventions/interventions_ui.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/modern_select_field.dart';

enum _RelanceCanal { telephone, mail, whatsapp }

class AdcRelanceScreen extends StatefulWidget {
  const AdcRelanceScreen({
    super.key,
    required this.adcId,
    this.initialDetail,
    this.fallbackSiteName,
    this.fallbackDatePlanifiee,
  });

  final String adcId;
  final ExperienceAdcDetail? initialDetail;
  final String? fallbackSiteName;
  final String? fallbackDatePlanifiee;

  @override
  State<AdcRelanceScreen> createState() => _AdcRelanceScreenState();
}

class _AdcRelanceScreenState extends State<AdcRelanceScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  ExperienceAdcDetail? _detail;

  _RelanceCanal _canal = _RelanceCanal.telephone;
  List<AdcContact> _contacts = [];
  String? _contactConcerneId;
  String? _phoneContactId;
  String _adcStatut = 'en_attente';
  String? _adcRessenti;
  List<AdcExchangeEntry> _exchangeHistory = [];

  String _lastSentMailMessage = '';
  String _lastSentWhatsappMessage = '';
  String _lastSentPhoneMessage = '';
  String _manualDateAppel = '';

  bool _showNonReponduRelances = false;

  final _observationsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _mailMessageCtrl = TextEditingController();
  final _whatsappMessageCtrl = TextEditingController();
  final _manualPhoneCtrl = TextEditingController();
  final _manualMailCtrl = TextEditingController();
  final _manualWhatsappCtrl = TextEditingController();
  final _dateAppelCtrl = TextEditingController();

  String? _mailTo;
  String? _whatsappPhone;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetail != null) {
      _detail = widget.initialDetail;
      _hydrateFromDetail(widget.initialDetail!);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _observationsCtrl.dispose();
    _notesCtrl.dispose();
    _mailMessageCtrl.dispose();
    _whatsappMessageCtrl.dispose();
    _manualPhoneCtrl.dispose();
    _manualMailCtrl.dispose();
    _manualWhatsappCtrl.dispose();
    _dateAppelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail =
          await context.read<AuthProvider>().api.getExperienceAdcDetail(widget.adcId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _hydrateFromDetail(detail);
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

  void _hydrateFromDetail(ExperienceAdcDetail d) {
    _contacts = List<AdcContact>.from(d.contacts);
    final refId = initialContactConcerneId(d);
    _contactConcerneId = refId.isNotEmpty ? refId : null;
    _adcStatut = (d.statut ?? 'en_attente').trim().isNotEmpty
        ? d.statut!.trim()
        : 'en_attente';
    final ressenti = ressentiToSelectValue(d.ressenti);
    _adcRessenti = ressenti.isEmpty ? null : ressenti;
    _lastSentMailMessage = d.relanceMailMessage ?? '';
    _lastSentWhatsappMessage = d.relanceWhatsappMessage ?? '';
    _lastSentPhoneMessage = d.relanceTelephoneMessage ?? '';
    _exchangeHistory = buildAdcExchangeHistory(
      trace: d.actionsTrace,
      relanceTelephoneMessage: d.relanceTelephoneMessage,
      adcRessenti: d.ressenti,
      agentFallback: _agentLabel(),
    );
    _phoneContactId = _contacts
        .where((c) => c.id == _contactConcerneId && (c.telephone ?? '').isNotEmpty)
        .map((c) => c.id)
        .firstOrNull ??
        _contactsForPhone.firstOrNull?.id;
    _mailTo = _contactsForMail.firstOrNull?.email;
    _whatsappPhone = _contactsForPhone.firstOrNull?.telephone;
    final historique = isAdcFicheHistorique(d.datePlanifiee);
    if (historique && (d.dateAppel ?? '').trim().isNotEmpty) {
      final raw = d.dateAppel!.trim();
      _manualDateAppel = raw.length >= 10 ? raw.substring(0, 10) : raw;
      _dateAppelCtrl.text = _manualDateAppel;
    }
  }

  String _agentLabel() {
    final auth = context.read<AuthProvider>();
    final me = auth.me;
    if (me != null) {
      final name = [
        (me['prenom'] as String? ?? '').trim(),
        (me['nom'] as String? ?? '').trim(),
      ].where((p) => p.isNotEmpty).join(' ');
      if (name.isNotEmpty) return name;
    }
    return auth.userEmail ?? '—';
  }

  bool get _isFicheHistorique => isAdcFicheHistorique(
        _detail?.datePlanifiee ?? widget.fallbackDatePlanifiee,
      );

  List<AdcContact> get _contactsForMail => _contacts
      .where((c) => (c.email ?? '').trim().isNotEmpty)
      .toList();

  List<AdcContact> get _contactsForPhone => _contacts
      .where((c) => (c.telephone ?? '').trim().isNotEmpty)
      .toList();

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }

  String _contactLabelFor(String value, String moyen) {
    final list = moyen == 'Mail' ? _contactsForMail : _contactsForPhone;
    for (final c in list) {
      final key = moyen == 'Mail' ? c.email : c.telephone;
      if (key == value) return '${c.nomAffiche} — $value';
    }
    return value;
  }

  void _onStatutChanged(String? v) {
    if (v == null) return;
    final prev = _adcStatut;
    setState(() {
      _adcStatut = v;
      if (v == 'non_répondu') {
        _adcRessenti = null;
        _showNonReponduRelances = prev != 'non_répondu';
      } else {
        _showNonReponduRelances = false;
      }
    });
  }

  void _appendHistory(AdcExchangeEntry entry) {
    setState(() => _exchangeHistory = [entry, ..._exchangeHistory]);
  }

  void _validerTelephone() {
    final obs = _observationsCtrl.text.trim();
    if (obs.isEmpty) {
      _snack('Renseignez les observations.', error: true);
      return;
    }
    if (_isFicheHistorique && _dateAppelCtrl.text.trim().isEmpty) {
      _snack('Renseignez la date de l’appel.', error: true);
      return;
    }

    final nextStatut = _adcStatut == 'en_attente' ? 'répondu' : _adcStatut;
    final statutLabel = adcStatutOptions
            .where((o) => o.value == nextStatut)
            .map((o) => o.label)
            .firstOrNull ??
        nextStatut;
    final ressentiVal = _adcRessenti ?? '';
    final ressentiLabel = ressentiVal.isEmpty
        ? ''
        : adcRessentiOptions
                .where((o) => o.value == ressentiVal)
                .map((o) => o.label)
                .firstOrNull ??
            ressentiVal;
    final resume = truncateAdcHist(
      [
        statutLabel,
        if (ressentiLabel.isNotEmpty) 'Ressenti $ressentiLabel',
        obs,
      ].join(' · '),
      180,
    );
    _lastSentPhoneMessage = toPhoneRelanceJson(
      message: obs,
      ressenti: ressentiVal.isNotEmpty ? ressentiVal : null,
    );

    final ref = _contacts.where((c) => c.id == _phoneContactId).firstOrNull ??
        _contacts.where((c) => c.id == _contactConcerneId).firstOrNull;
    if (ref != null) _contactConcerneId = ref.id;
    final contactLabel = ref != null
        ? '${ref.nomAffiche}${(ref.telephone ?? '').trim().isNotEmpty ? ' — ${ref.telephone}' : ''}'
        : '—';

    final dateIso = _isFicheHistorique && _dateAppelCtrl.text.trim().isNotEmpty
        ? '${_dateAppelCtrl.text.trim()}T12:00:00.000Z'
        : null;

    _appendHistory(
      newAdcExchangeEntry(
        agent: _agentLabel(),
        moyen: 'Téléphone',
        resume: resume.isNotEmpty ? resume : obs,
        contactLabel: contactLabel,
        dateIso: dateIso,
        notesAppel: obs,
        ressenti: ressentiVal.isNotEmpty ? '$ressentiVal/10' : null,
      ),
    );

    setState(() {
      if (nextStatut != _adcStatut) _adcStatut = nextStatut;
      _observationsCtrl.clear();
      _notesCtrl.clear();
    });
    _snack('Appel ajouté à l’historique');
  }

  Future<void> _envoyerMail() async {
    final to = (_mailTo ?? _manualMailCtrl.text).trim();
    final corps = _mailMessageCtrl.text.trim();
    if (to.isEmpty) {
      _snack('Indiquez un destinataire.', error: true);
      return;
    }
    if (corps.isEmpty) {
      _snack('Saisissez un message.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().api.sendCommunication(
            message: corps,
            contact: to,
            channel: 'mail',
            subject: 'Relance ADC — ${_detail?.clientName ?? 'client'}',
          );
      _lastSentMailMessage = _mailMessageCtrl.text;
      _appendHistory(
        newAdcExchangeEntry(
          agent: _agentLabel(),
          moyen: 'Mail',
          resume: truncateAdcHist(corps, 160),
          contactLabel: _contactLabelFor(to, 'Mail'),
          messageCorps: corps,
        ),
      );
      _mailMessageCtrl.clear();
      _snack('Relance mail enregistrée');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _envoyerWhatsapp() async {
    final phone = digitsOnlyPhone(
      _whatsappPhone ?? _manualWhatsappCtrl.text,
    );
    final corps = _whatsappMessageCtrl.text.trim();
    if (phone.isEmpty) {
      _snack('Indiquez un numéro valide.', error: true);
      return;
    }
    if (corps.isEmpty) {
      _snack('Saisissez un message.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().api.sendCommunication(
            message: corps,
            contact: phone,
            channel: 'whatsapp',
          );
      _lastSentWhatsappMessage = _whatsappMessageCtrl.text;
      _appendHistory(
        newAdcExchangeEntry(
          agent: _agentLabel(),
          moyen: 'WhatsApp',
          resume: truncateAdcHist(corps, 160),
          contactLabel: _contactLabelFor(
            _whatsappPhone ?? _manualWhatsappCtrl.text,
            'WhatsApp',
          ),
          messageCorps: corps,
          ressenti: formatAdcRessentiLabel(_adcRessenti),
        ),
      );
      _whatsappMessageCtrl.clear();
      _snack('Relance WhatsApp enregistrée');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _enregistrerRelancesNonRepondu() {
    final wa = _whatsappMessageCtrl.text.trim();
    final mail = _mailMessageCtrl.text.trim();
    if (wa.isNotEmpty) {
      _lastSentWhatsappMessage = _whatsappMessageCtrl.text;
      _appendHistory(
        newAdcExchangeEntry(
          agent: _agentLabel(),
          moyen: 'WhatsApp',
          resume: truncateAdcHist(wa, 160),
          contactLabel: _contactLabelFor(
            _whatsappPhone ?? _manualWhatsappCtrl.text,
            'WhatsApp',
          ),
          messageCorps: _whatsappMessageCtrl.text,
        ),
      );
    }
    if (mail.isNotEmpty) {
      _lastSentMailMessage = _mailMessageCtrl.text;
      _appendHistory(
        newAdcExchangeEntry(
          agent: _agentLabel(),
          moyen: 'Mail',
          resume: truncateAdcHist(mail, 160),
          contactLabel: _contactLabelFor(
            _mailTo ?? _manualMailCtrl.text,
            'Mail',
          ),
          messageCorps: _mailMessageCtrl.text,
        ),
      );
    }
    setState(() => _showNonReponduRelances = false);
    _snack(
      wa.isEmpty && mail.isEmpty
          ? 'Aucun message saisi'
          : 'Relances enregistrées',
    );
  }

  Future<void> _saveAll() async {
    final d = _detail;
    if (d == null) return;
    if (_exchangeHistory.isEmpty) {
      _snack('Ajoutez au moins une relance avant d’enregistrer.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final body = buildAdcPatchBody(
        contactConcerneId: _contactConcerneId,
        adcStatut: _adcStatut,
        adcRessenti: _adcRessenti ?? '',
        observations: _observationsCtrl.text,
        exchangeHistory: _exchangeHistory,
        lastSentMailMessage: _lastSentMailMessage,
        lastSentWhatsappMessage: _lastSentWhatsappMessage,
        lastSentPhoneMessage: _lastSentPhoneMessage,
        isFicheHistorique: _isFicheHistorique,
        manualDateAppel: _dateAppelCtrl.text.trim().isNotEmpty
            ? _dateAppelCtrl.text.trim()
            : _manualDateAppel,
      );
      await context.read<AuthProvider>().api.patchExperienceAdc(d.id, body);
      if (!mounted) return;
      _snack('Fiche ADC enregistrée');
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addContact() async {
    final clientId = (_detail?.clientId ?? '').trim();
    if (clientId.isEmpty) {
      _snack('Aucun client lié.', error: true);
      return;
    }

    final created = await showModernBottomSheet<AdcContact>(
      context: context,
      builder: (ctx) => _AddContactSheet(
        clientId: clientId,
        siteId: _detail?.siteId,
      ),
    );

    if (created == null || !mounted) return;
    setState(() {
      _contacts = [..._contacts, created];
      _contactConcerneId ??= created.id;
      _phoneContactId ??=
          (created.telephone ?? '').isNotEmpty ? created.id : null;
      _mailTo ??= created.email;
      _whatsappPhone ??= created.telephone;
    });
    _snack('Contact ajouté');
  }

  Widget _buildStatutRessentiFields() {
    final hideRessenti = _adcStatut == 'non_répondu';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModernSelectField<String>(
          label: 'Statut',
          hint: 'Choisir',
          value: _adcStatut,
          allowClear: false,
          options: adcStatutOptions
              .map(
                (o) => ModernSelectOption(
                  value: o.value,
                  label: o.label,
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) _onStatutChanged(v);
          },
        ),
        if (!hideRessenti) ...[
          const SizedBox(height: 16),
          ModernSelectField<String>(
            label: 'Ressenti client (0–10)',
            hint: 'Non renseigné',
            value: _adcRessenti,
            options: adcRessentiOptions
                .where((o) => o.value.isNotEmpty)
                .map(
                  (o) => ModernSelectOption(
                    value: o.value,
                    label: o.label,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _adcRessenti = v),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: InterventionsUi.canvasSoft,
      appBar: AppBar(
        backgroundColor: InterventionsUi.canvasSoft,
        foregroundColor: AromaColors.zinc900,
        elevation: 0,
        title: const Text('Nouvelle relance'),
        actions: [
          IconButton(
            onPressed: _addContact,
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Ajouter un contact',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? interventionsErrorState(message: _error!, onRetry: _load)
              : d == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              _ClientBanner(detail: d),
                              const SizedBox(height: 20),
                              _SectionLabel('Canal de communication'),
                              const SizedBox(height: 10),
                              _CanalSelector(
                                value: _canal,
                                onChanged: (c) => setState(() => _canal = c),
                              ),
                              const SizedBox(height: 24),
                              if (_canal == _RelanceCanal.telephone ||
                                  _canal == _RelanceCanal.whatsapp) ...[
                                _SectionLabel('Statut et ressenti'),
                                const SizedBox(height: 10),
                                _RelanceCard(child: _buildStatutRessentiFields()),
                                const SizedBox(height: 24),
                              ],
                              _SectionLabel(_canalLabel),
                              const SizedBox(height: 10),
                              _RelanceCard(child: _buildCanalForm()),
                              if (_showNonReponduRelances) ...[
                                const SizedBox(height: 16),
                                _RelanceCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Relances — client non répondu',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Messages WhatsApp et/ou mail à enregistrer.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AromaColors.zinc500,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _whatsappMessageCtrl,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Message WhatsApp',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _mailMessageCtrl,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Message mail',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: _enregistrerRelancesNonRepondu,
                                        child: const Text('Enregistrer les relances'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_exchangeHistory.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _SectionLabel(
                                  'Historique (${_exchangeHistory.length})',
                                ),
                                const SizedBox(height: 10),
                                _RelanceCard(
                                  child: Column(
                                    children: [
                                      for (var i = 0;
                                          i < _exchangeHistory.length;
                                          i++) ...[
                                        if (i > 0) const Divider(height: 20),
                                        _HistoryPreviewRow(
                                          entry: _exchangeHistory[i],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                          decoration: BoxDecoration(
                            color: AromaColors.surface,
                            border: Border(
                              top: BorderSide(color: AromaColors.zinc200),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveAll,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _saving
                                  ? 'Enregistrement…'
                                  : 'Enregistrer et valider',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: AromaColors.zinc900,
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  String get _canalLabel {
    switch (_canal) {
      case _RelanceCanal.telephone:
        return 'Relance téléphonique';
      case _RelanceCanal.mail:
        return 'Relance mail';
      case _RelanceCanal.whatsapp:
        return 'Relance WhatsApp';
    }
  }

  Widget _buildCanalForm() {
    switch (_canal) {
      case _RelanceCanal.telephone:
        return _buildPhoneForm();
      case _RelanceCanal.mail:
        return _buildMailForm();
      case _RelanceCanal.whatsapp:
        return _buildWhatsappForm();
    }
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_contactsForPhone.isNotEmpty)
          ModernSelectField<String>(
            label: 'Contact appelé',
            hint: 'Choisir le contact',
            value: _phoneContactId,
            allowClear: false,
            options: _contactsForPhone
                .map(
                  (c) => ModernSelectOption(
                    value: c.id,
                    label: c.nomAffiche,
                    subtitle: c.telephone,
                    icon: Icons.phone_in_talk_outlined,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _phoneContactId = v),
          )
        else
          TextField(
            controller: _manualPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro composé',
            ),
          ),
        const SizedBox(height: 16),
        if (_isFicheHistorique) ...[
          TextField(
            controller: _dateAppelCtrl,
            decoration: const InputDecoration(
              labelText: 'Date de l’appel',
              hintText: 'AAAA-MM-JJ',
            ),
            onChanged: (v) => _manualDateAppel = v,
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _observationsCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observations *',
            hintText: 'Résumé de l’appel…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Détail (optionnel)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _validerTelephone,
          icon: const Icon(Icons.phone_callback_outlined, size: 20),
          label: const Text('Valider l’appel'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color(0xFF047857),
          ),
        ),
      ],
    );
  }

  Widget _buildMailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_contactsForMail.isNotEmpty)
          ModernSelectField<String>(
            label: 'Destinataire',
            hint: 'Choisir un email',
            value: _mailTo,
            options: _contactsForMail
                .map(
                  (c) => ModernSelectOption(
                    value: c.email!,
                    label: c.nomAffiche,
                    subtitle: c.email,
                    icon: Icons.email_outlined,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _mailTo = v),
          )
        else
          TextField(
            controller: _manualMailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email destinataire'),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _mailMessageCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _envoyerMail,
          icon: const Icon(Icons.send_outlined, size: 20),
          label: const Text('Envoyer et enregistrer'),
        ),
      ],
    );
  }

  Widget _buildWhatsappForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_contactsForPhone.isNotEmpty)
          ModernSelectField<String>(
            label: 'Contact',
            hint: 'Choisir un numéro',
            value: _whatsappPhone,
            options: _contactsForPhone
                .map(
                  (c) => ModernSelectOption(
                    value: c.telephone!,
                    label: c.nomAffiche,
                    subtitle: c.telephone,
                    icon: Icons.chat_outlined,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _whatsappPhone = v),
          )
        else
          TextField(
            controller: _manualWhatsappCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Numéro WhatsApp'),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _whatsappMessageCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _envoyerWhatsapp,
          icon: const Icon(Icons.send_outlined, size: 20),
          label: const Text('Envoyer et enregistrer'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
          ),
        ),
      ],
    );
  }
}

class _ClientBanner extends StatelessWidget {
  const _ClientBanner({required this.detail});

  final ExperienceAdcDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: InterventionsUi.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: InterventionsUi.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.clientName ?? 'Client',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.siteName ?? '—',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Planifié · ${formatDateFr(detail.datePlanifiee)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AromaColors.zinc500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _RelanceCard extends StatelessWidget {
  const _RelanceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: InterventionsUi.softCardDecoration(),
      child: child,
    );
  }
}

class _CanalSelector extends StatelessWidget {
  const _CanalSelector({
    required this.value,
    required this.onChanged,
  });

  final _RelanceCanal value;
  final ValueChanged<_RelanceCanal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CanalChip(
            label: 'Téléphone',
            icon: Icons.phone_in_talk_rounded,
            selected: value == _RelanceCanal.telephone,
            color: const Color(0xFF047857),
            onTap: () => onChanged(_RelanceCanal.telephone),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CanalChip(
            label: 'Mail',
            icon: Icons.mail_outline_rounded,
            selected: value == _RelanceCanal.mail,
            color: const Color(0xFF2563EB),
            onTap: () => onChanged(_RelanceCanal.mail),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CanalChip(
            label: 'WhatsApp',
            icon: Icons.chat_outlined,
            selected: value == _RelanceCanal.whatsapp,
            color: const Color(0xFF25D366),
            onTap: () => onChanged(_RelanceCanal.whatsapp),
          ),
        ),
      ],
    );
  }
}

class _CanalChip extends StatelessWidget {
  const _CanalChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AromaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AromaColors.zinc200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AromaColors.zinc500, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AromaColors.zinc500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPreviewRow extends StatelessWidget {
  const _HistoryPreviewRow({required this.entry});

  final AdcExchangeEntry entry;

  @override
  Widget build(BuildContext context) {
    final ressenti = formatAdcRessentiLabel(entry.ressenti);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: InterventionsUi.accentMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.moyen,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: InterventionsUi.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            adcExchangeResumeText(entry),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.dateAffiche,
              style: const TextStyle(
                fontSize: 11,
                color: AromaColors.zinc500,
              ),
            ),
            if (ressenti != null) ...[
              const SizedBox(height: 2),
              Text(
                'Ressenti $ressenti',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: InterventionsUi.accent,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet({
    required this.clientId,
    this.siteId,
  });

  final String clientId;
  final String? siteId;

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  String? _civilite;
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _posteCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await context.read<AuthProvider>().api.createContactClient(
            idTiers: widget.clientId,
            idAgence: widget.siteId,
            civilite: _civilite,
            prenom: _prenomCtrl.text.trim().isEmpty
                ? null
                : _prenomCtrl.text.trim(),
            nom: _nomCtrl.text.trim(),
            poste: _posteCtrl.text.trim().isEmpty ? null : _posteCtrl.text.trim(),
            telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
            typeContact: 'adc',
          );
      if (!mounted) return;
      Navigator.of(context).pop(adcContactFromClient(created));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ModernBottomSheetShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              modernSheetDragHandle(),
              const SizedBox(height: 16),
              const ModernSheetHeader(
                title: 'Nouveau contact',
                subtitle: 'Enregistré pour ce client et ce site',
                theme: ModernSheetThemes.interventions,
              ),
              const SizedBox(height: 24),
              ModernSelectField<String>(
                label: 'Civilité',
                hint: 'Choisir',
                value: _civilite,
                clearLabel: 'Non renseignée',
                options: contactCiviliteOptions
                    .where((v) => v.isNotEmpty)
                    .map(
                      (v) => ModernSelectOption(
                        value: v,
                        label: v,
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _civilite = v),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ContactField(
                      controller: _prenomCtrl,
                      label: 'Prénom',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactField(
                      controller: _nomCtrl,
                      label: 'Nom *',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _posteCtrl,
                label: 'Poste',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _telCtrl,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: InterventionsUi.accent,
                      ),
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

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: InterventionsUi.accent, size: 22),
        filled: true,
        fillColor: InterventionsUi.accentMuted.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: InterventionsUi.accentSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: InterventionsUi.accent, width: 1.5),
        ),
      ),
    );
  }
}
