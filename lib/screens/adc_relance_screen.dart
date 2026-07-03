import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intervention.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/adc_exchange_history.dart';
import '../utils/adc_form_logic.dart';
import '../utils/format_utils.dart';
import '../widgets/interventions/interventions_ui.dart';
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
  final Set<String> _selectedContactIds = {};
  String? _contactConcerneId;
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
    _selectedContactIds.clear();
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

  List<AdcContact> get _contactsForMail {
    final withEmail =
        _contacts.where((c) => (c.email ?? '').trim().isNotEmpty).toList();
    if (_selectedContactIds.isEmpty) return withEmail;
    return withEmail.where((c) => _selectedContactIds.contains(c.id)).toList();
  }

  List<AdcContact> get _contactsForPhone {
    final withPhone =
        _contacts.where((c) => (c.telephone ?? '').trim().isNotEmpty).toList();
    if (_selectedContactIds.isEmpty) return withPhone;
    return withPhone.where((c) => _selectedContactIds.contains(c.id)).toList();
  }

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

    final ref = _contacts.where((c) => c.id == _contactConcerneId).firstOrNull;
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
    final nomCtrl = TextEditingController();
    final posteCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final api = context.read<AuthProvider>().api;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
              ),
              TextField(
                controller: posteCtrl,
                decoration: const InputDecoration(labelText: 'Poste'),
              ),
              TextField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      nomCtrl.dispose();
      posteCtrl.dispose();
      telCtrl.dispose();
      emailCtrl.dispose();
      return;
    }

    if (nomCtrl.text.trim().isEmpty) {
      _snack('Le nom est requis.', error: true);
      nomCtrl.dispose();
      posteCtrl.dispose();
      telCtrl.dispose();
      emailCtrl.dispose();
      return;
    }

    try {
      final created = await api.createContactClient(
            idTiers: clientId,
            idAgence: _detail?.siteId,
            nom: nomCtrl.text.trim(),
            poste: posteCtrl.text.trim().isEmpty ? null : posteCtrl.text.trim(),
            telephone: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            typeContact: 'adc',
          );
      if (!mounted) return;
      final mapped = adcContactFromClient(created);
      setState(() {
        _contacts = [..._contacts, mapped];
        _contactConcerneId ??= mapped.id;
        _mailTo ??= mapped.email;
        _whatsappPhone ??= mapped.telephone;
      });
      _snack('Contact ajouté');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      nomCtrl.dispose();
      posteCtrl.dispose();
      telCtrl.dispose();
      emailCtrl.dispose();
    }
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
                              _SectionLabel('Contacts'),
                              const SizedBox(height: 10),
                              _RelanceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Référent ADC',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: _addContact,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Contact'),
                                        ),
                                      ],
                                    ),
                                    if (_contacts.isEmpty)
                                      const Text(
                                        'Aucun contact — ajoutez-en un.',
                                        style: TextStyle(
                                          color: AromaColors.zinc500,
                                        ),
                                      )
                                    else
                                      ModernSelectField<String>(
                                        label: 'Contact référent',
                                        hint: 'Choisir un contact',
                                        value: _contactConcerneId,
                                        options: _contacts
                                            .map(
                                              (c) => ModernSelectOption(
                                                value: c.id,
                                                label: c.nomAffiche,
                                                subtitle: c.poste,
                                                icon: Icons.person_outline,
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _contactConcerneId = v),
                                      ),
                                    if (_contacts.length > 1) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Cibler pour les relances (optionnel)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AromaColors.zinc500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._contacts.map(
                                        (c) => CheckboxListTile(
                                          value: _selectedContactIds.contains(c.id),
                                          onChanged: (_) {
                                            setState(() {
                                              if (_selectedContactIds
                                                  .contains(c.id)) {
                                                _selectedContactIds.remove(c.id);
                                              } else {
                                                _selectedContactIds.add(c.id);
                                              }
                                            });
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(c.nomAffiche),
                                          subtitle: Text(
                                            [
                                              if ((c.telephone ?? '').isNotEmpty)
                                                c.telephone!,
                                              if ((c.email ?? '').isNotEmpty)
                                                c.email!,
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
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
        const SizedBox(height: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.resume,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                entry.dateAffiche,
                style: const TextStyle(
                  fontSize: 11,
                  color: AromaColors.zinc500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
