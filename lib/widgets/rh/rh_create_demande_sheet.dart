import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/demande_rh.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import 'rh_ui.dart';

class RhCreateDemandeSheet extends StatefulWidget {
  const RhCreateDemandeSheet({super.key, required this.collaborateurId});

  final String collaborateurId;

  @override
  State<RhCreateDemandeSheet> createState() => _RhCreateDemandeSheetState();
}

class _RhCreateDemandeSheetState extends State<RhCreateDemandeSheet> {
  String _type = 'Absence';
  DateTime? _debut;
  DateTime? _fin;
  final _motif = TextEditingController();
  final _montant = TextEditingController();
  bool _submitting = false;
  String? _filePath;

  @override
  void dispose() {
    _motif.dispose();
    _montant.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isDebut) {
        _debut = picked;
        if (_fin == null || _fin!.isBefore(picked)) _fin = picked;
      } else {
        _fin = picked;
      }
    });
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.single.path != null) {
      setState(() => _filePath = res.files.single.path);
    }
  }

  Future<void> _submit() async {
    if (_debut == null || _fin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez les dates de début et fin.')),
      );
      return;
    }
    if (_type == 'Avance de Paiement' &&
        (double.tryParse(_montant.text.replaceAll(',', '.')) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant requis pour une avance.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final docs = <Map<String, dynamic>>[];
      if (_filePath != null) {
        final uploaded = await auth.api.uploadDemandeRhDocuments([_filePath!]);
        docs.addAll(uploaded);
      }

      final body = <String, dynamic>{
        'id_collaborateur': widget.collaborateurId,
        'type': _type,
        'date_debut': _fmtDate(_debut!),
        'date_fin': _type == 'Avance de Paiement'
            ? _fmtDate(_debut!)
            : _fmtDate(_fin!),
        'statut': 'en_attente',
      };
      final motif = _motif.text.trim();
      if (motif.isNotEmpty) body['motif'] = motif;
      if (_type == 'Avance de Paiement') {
        body['montant'] = double.parse(_montant.text.replaceAll(',', '.'));
      }
      if (docs.isNotEmpty) body['documents'] = docs;

      await auth.api.createDemandeRh(body);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée.')),
      );
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
    return Container(
      decoration: const BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: RhUi.gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nouvelle demande RH',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de demande'),
                items: rhDemandeTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              RhUi.typeDemandeIcon(t),
                              size: 18,
                              color: RhUi.accent,
                            ),
                            const SizedBox(width: 10),
                            Text(labelTypeDemande(t)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              _DateTile(
                label: 'Date début',
                value: _debut != null ? formatDateFr(_fmtDate(_debut!)) : null,
                onTap: () => _pickDate(true),
              ),
              if (_type != 'Avance de Paiement')
                _DateTile(
                  label: 'Date fin',
                  value: _fin != null ? formatDateFr(_fmtDate(_fin!)) : null,
                  onTap: () => _pickDate(false),
                ),
              if (_type == 'Avance de Paiement') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _montant,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (F CFA)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _motif,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motif (optionnel)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _filePath != null
                      ? 'Justificatif sélectionné'
                      : 'Ajouter un justificatif',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.onTap,
    this.value,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 20, color: RhUi.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AromaColors.zinc500,
                      ),
                    ),
                    Text(
                      value ?? 'Choisir une date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: value != null
                            ? AromaColors.zinc900
                            : AromaColors.zinc500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AromaColors.zinc500),
            ],
          ),
        ),
      ),
    );
  }
}
