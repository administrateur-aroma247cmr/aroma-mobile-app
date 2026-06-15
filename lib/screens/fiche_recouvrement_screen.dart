import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recouvrement.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';

class FicheRecouvrementScreen extends StatefulWidget {
  const FicheRecouvrementScreen({super.key, required this.facture});

  final FactureRecouvrementItem facture;

  @override
  State<FicheRecouvrementScreen> createState() =>
      _FicheRecouvrementScreenState();
}

class _FicheRecouvrementScreenState extends State<FicheRecouvrementScreen> {
  bool _loading = true;
  String? _error;
  RecouvrementDetail? _detail;
  final _mailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _mailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final detail = await api.getRecouvrementDetail(widget.facture.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _mailCtrl.text = detail.relanceMailMessage ?? '';
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

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (!auth.canEditRecouvrement) return;
    setState(() => _saving = true);
    try {
      await auth.api.patchRecouvrement(widget.facture.id, {
        if (_mailCtrl.text.trim().isNotEmpty)
          'relance_mail_message': _mailCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiche enregistrée.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facture;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: Text('Recouvrement — ${f.nomClient}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails facture',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _Row('Client', f.nomClient),
                        _Row('N° facture', f.refFacture),
                        _Row('Montant', fmtFcfa(f.montant)),
                        _Row('Date attendue', formatDateFr(f.dateAttendu)),
                        if (f.joursRetard > 0)
                          _Row('Jours de retard', '${f.joursRetard}'),
                        if (f.statut != null) _Row('Statut', f.statut!),
                        if (_detail?.assigneNom != null)
                          _Row('Assigné à', _detail!.assigneNom!),
                        if (_detail?.nombreRelances != null)
                          _Row('Relances', '${_detail!.nombreRelances}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relance mail',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mailCtrl,
                          maxLines: 4,
                          readOnly: !auth.canEditRecouvrement,
                          decoration: const InputDecoration(
                            hintText: 'Message de relance…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if ((_detail?.relanceWhatsappMessage ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _Row('WhatsApp', _detail!.relanceWhatsappMessage!),
                        ],
                        if ((_detail?.relanceTelephoneMessage ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _Row('Téléphone', _detail!.relanceTelephoneMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_detail != null && _detail!.actionsTrace.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historique des échanges',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ..._detail!.actionsTrace.map(
                            (e) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${e['moyen'] ?? e['agent'] ?? '—'}'),
                              subtitle: Text(
                                '${e['date'] ?? e['created_at'] ?? ''}\n'
                                '${e['resume'] ?? e['contenu'] ?? ''}',
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (auth.canEditRecouvrement) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer et valider'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AromaColors.zinc500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
