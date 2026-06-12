import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collaborateur.dart';
import '../models/demande_rh.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';
import 'rh_recap_screen.dart';

class RhHubScreen extends StatefulWidget {
  const RhHubScreen({super.key});

  @override
  State<RhHubScreen> createState() => _RhHubScreenState();
}

class _RhHubScreenState extends State<RhHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Mon espace RH'),
        actions: const [EntityScopeAppBarAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Mon profil'),
            Tab(text: 'Mon récap'),
            Tab(text: 'Mes demandes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RhProfilTab(),
          RhRecapScreen(embedded: true),
          _RhDemandesTab(),
        ],
      ),
    );
  }
}

class _RhProfilTab extends StatefulWidget {
  const _RhProfilTab();

  @override
  State<_RhProfilTab> createState() => _RhProfilTabState();
}

class _RhProfilTabState extends State<_RhProfilTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  Collaborateur? _collab;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    final id = auth.collaborateurId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Aucun profil collaborateur lié à ce compte.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await auth.api.getCollaborateur(id);
      if (!mounted) return;
      setState(() {
        _collab = c;
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

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    final c = _collab!;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AromaColors.zinc100,
                    child: Text(
                      c.prenom.isNotEmpty ? c.prenom[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (c.poste != null && c.poste!.isNotEmpty)
                    Text(
                      c.poste!,
                      style: const TextStyle(color: AromaColors.zinc500),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Coordonnées',
            rows: [
              _InfoRow('Email pro', c.emailPro),
              _InfoRow('Email perso', c.emailPerso),
              _InfoRow('Tél. pro', c.telPro),
              _InfoRow('Tél. perso', c.telPerso),
              _InfoRow('Urgence', c.personneContactUrgence),
            ],
          ),
          _InfoSection(
            title: 'Contrat',
            rows: [
              _InfoRow('Matricule', c.matricule),
              _InfoRow('Type contrat', c.typeContrat),
              _InfoRow('Catégorie', c.categorieSociale),
              _InfoRow('Entrée', formatDateFr(c.dateEntreeDebut)),
              _InfoRow('Embauche', formatDateFr(c.dateEmbauche)),
            ],
          ),
          _InfoSection(
            title: 'Identité',
            rows: [
              _InfoRow('Naissance', formatDateFr(c.dateNaissance)),
              _InfoRow('Lieu', c.lieuNaissance),
              _InfoRow('CNI', c.cni),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;
}

class _RhDemandesTab extends StatefulWidget {
  const _RhDemandesTab();

  @override
  State<_RhDemandesTab> createState() => _RhDemandesTabState();
}

class _RhDemandesTabState extends State<_RhDemandesTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<DemandeRh> _demandes = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AuthProvider>().api.listDemandesRh();
      if (!mounted) return;
      setState(() {
        _demandes = list;
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

  Future<void> _openCreateDialog() async {
    final auth = context.read<AuthProvider>();
    if (!auth.canCreateRhDemande) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Création de demande non autorisée pour ce compte.'),
        ),
      );
      return;
    }
    final collabId = auth.collaborateurId;
    if (collabId == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CreateDemandeSheet(collaborateurId: collabId),
    );
    if (result == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final canCreate = context.watch<AuthProvider>().canCreateRhDemande;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle demande'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _reload,
              child: _demandes.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Aucune demande RH.',
                            style: TextStyle(color: AromaColors.zinc500),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _demandes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = _demandes[i];
                        return Card(
                          child: ListTile(
                            title: Text(labelTypeDemande(d.type)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${formatDateFr(d.dateDebut)} → ${formatDateFr(d.dateFin)}',
                                ),
                                if (d.motif != null && d.motif!.isNotEmpty)
                                  Text(d.motif!),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  labelStatutDemande(d.statut),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (d.montant != null && d.montant! > 0)
                                  Text(fmtFcfa(d.montant)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _CreateDemandeSheet extends StatefulWidget {
  const _CreateDemandeSheet({required this.collaborateurId});

  final String collaborateurId;

  @override
  State<_CreateDemandeSheet> createState() => _CreateDemandeSheetState();
}

class _CreateDemandeSheetState extends State<_CreateDemandeSheet> {
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nouvelle demande RH',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: rhDemandeTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(labelTypeDemande(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date début'),
              subtitle: Text(
                _debut != null ? formatDateFr(_fmtDate(_debut!)) : 'Choisir',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(true),
            ),
            if (_type != 'Avance de Paiement')
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date fin'),
                subtitle: Text(
                  _fin != null ? formatDateFr(_fmtDate(_fin!)) : 'Choisir',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(false),
              ),
            if (_type == 'Avance de Paiement')
              TextField(
                controller: _montant,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (F CFA)',
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _motif,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif (optionnel)',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _filePath != null ? 'Justificatif sélectionné' : 'Justificatif',
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
    );
  }
}
