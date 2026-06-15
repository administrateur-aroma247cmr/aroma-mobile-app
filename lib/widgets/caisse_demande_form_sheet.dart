import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/demande_a_payer.dart';
import '../providers/auth_provider.dart';

class CaisseDemandeFormSheet extends StatefulWidget {
  const CaisseDemandeFormSheet({super.key, this.demande});

  final DemandeAPayer? demande;

  @override
  State<CaisseDemandeFormSheet> createState() => _CaisseDemandeFormSheetState();
}

class _CaisseDemandeFormSheetState extends State<CaisseDemandeFormSheet> {
  final _client = TextEditingController();
  final _raison = TextEditingController();
  final _raisonTransport = TextEditingController();
  final _montant = TextEditingController();
  DateTime? _dateDecaisse;
  bool _submitting = false;
  bool _submitForValidation = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    final d = widget.demande;
    if (d != null) {
      _client.text = d.client;
      _raison.text = d.raisonBonCommande;
      _raisonTransport.text = d.raisonBonTransport ?? '';
      _montant.text = d.montantDemande.toStringAsFixed(0);
      if (d.dateADecaisser != null) {
        final p = d.dateADecaisser!.split('-');
        if (p.length >= 3) {
          _dateDecaisse = DateTime(
            int.tryParse(p[0]) ?? DateTime.now().year,
            int.tryParse(p[1]) ?? DateTime.now().month,
            int.tryParse(p[2]) ?? DateTime.now().day,
          );
        }
      }
    } else {
      _raisonTransport.text = '—';
      _dateDecaisse = DateTime.now();
    }
  }

  @override
  void dispose() {
    _client.dispose();
    _raison.dispose();
    _raisonTransport.dispose();
    _montant.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final client = _client.text.trim();
    final raison = _raison.text.trim();
    final montant = double.tryParse(_montant.text.replaceAll(',', '.'));
    if (client.isEmpty || raison.isEmpty || montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client, raison et montant requis.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final docs = <Map<String, dynamic>>[];
      if (_filePath != null) {
        docs.addAll(
          await auth.api.uploadDemandesAPayerJustificatifs([_filePath!]),
        );
      }
      final body = <String, dynamic>{
        'client': client,
        'raison_bon_commande': raison,
        'raison_bon_transport': _raisonTransport.text.trim().isEmpty
            ? '—'
            : _raisonTransport.text.trim(),
        'montant_demande': montant,
        'date_a_decaisser': _dateDecaisse != null
            ? _fmt(_dateDecaisse!)
            : _fmt(DateTime.now()),
        'statut': _submitForValidation
            ? 'Soumis en attente de validations'
            : 'Brouillon',
      };
      if (docs.isNotEmpty) body['justificatifs'] = docs;

      if (widget.demande == null) {
        await auth.api.createDemandeAPayer(body);
      } else {
        await auth.api.patchDemandeAPayer(widget.demande!.id, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.demande == null
                  ? 'Nouvelle demande à payer'
                  : 'Modifier la demande',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _client,
              decoration: const InputDecoration(labelText: 'Client *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _raison,
              decoration: const InputDecoration(
                labelText: 'Raison bon de commande *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _raisonTransport,
              decoration: const InputDecoration(
                labelText: 'Raison bon de transport',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montant,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (F CFA) *',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date à décaisser'),
              subtitle: Text(
                _dateDecaisse != null
                    ? '${_dateDecaisse!.day}/${_dateDecaisse!.month}/${_dateDecaisse!.year}'
                    : 'Choisir',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateDecaisse ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dateDecaisse = picked);
              },
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles();
                if (res?.files.single.path != null) {
                  setState(() => _filePath = res!.files.single.path);
                }
              },
              icon: const Icon(Icons.attach_file),
              label: Text(
                _filePath != null ? 'Justificatif ajouté' : 'Justificatif',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Soumettre pour validation'),
              value: _submitForValidation,
              onChanged: (v) => setState(() => _submitForValidation = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
