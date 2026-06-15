import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collaborateur.dart';
import '../models/demande_rh.dart';
import '../models/tache.dart';
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

class _RhHubScreenState extends State<RhHubScreen> {
  String? _selectedCollabId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.canViewRhExecutiveTabs) {
      if (_selectedCollabId != null) {
        return _RhCollaborateurDetailShell(
          collaborateurId: _selectedCollabId!,
          onBack: () => setState(() => _selectedCollabId = null),
        );
      }
      return _RhExecutiveShell(
        onSelectCollaborateur: (id) => setState(() => _selectedCollabId = id),
      );
    }
    return const _RhCollaborateurShell();
  }
}

class _RhExecutiveShell extends StatefulWidget {
  const _RhExecutiveShell({required this.onSelectCollaborateur});

  final ValueChanged<String> onSelectCollaborateur;

  @override
  State<_RhExecutiveShell> createState() => _RhExecutiveShellState();
}

class _RhExecutiveShellState extends State<_RhExecutiveShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<CollaborateurLite> _collaborateurs = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<AuthProvider>().api.listCollaborateursLite();
      if (!mounted) return;
      setState(() {
        _collaborateurs = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.trim().toLowerCase();
    final filtered = _collaborateurs.where((c) {
      if (q.isEmpty) return true;
      return c.fullName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Espace RH — Direction'),
        actions: const [EntityScopeAppBarAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Mes collaborateurs'),
            Tab(text: 'Mes demandes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher collaborateur…',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: filtered.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text('Aucun collaborateur.'),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final c = filtered[i];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          c.prenom.isNotEmpty
                                              ? c.prenom[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      title: Text(c.fullName),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () =>
                                          widget.onSelectCollaborateur(c.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
          const _RhDemandesTab(executiveAll: true),
        ],
      ),
    );
  }
}

class _RhCollaborateurDetailShell extends StatefulWidget {
  const _RhCollaborateurDetailShell({
    required this.collaborateurId,
    required this.onBack,
  });

  final String collaborateurId;
  final VoidCallback onBack;

  @override
  State<_RhCollaborateurDetailShell> createState() =>
      _RhCollaborateurDetailShellState();
}

class _RhCollaborateurDetailShellState extends State<_RhCollaborateurDetailShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final c = await context.read<AuthProvider>().api.getCollaborateur(
        widget.collaborateurId,
      );
      if (!mounted) return;
      setState(() => _name = c.fullName);
    } catch (_) {}
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(_name.isEmpty ? 'Collaborateur' : _name),
        actions: const [EntityScopeAppBarAction()],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Récap'),
            Tab(text: 'Demandes'),
            Tab(text: 'Présence'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RhProfilTab(collaborateurId: widget.collaborateurId),
          RhRecapScreen(
            embedded: true,
            collaborateurId: widget.collaborateurId,
          ),
          _RhDemandesTab(collaborateurId: widget.collaborateurId),
          _RhPresenceTab(collaborateurId: widget.collaborateurId),
          _RhDocumentsTab(collaborateurId: widget.collaborateurId),
        ],
      ),
    );
  }
}

class _RhCollaborateurShell extends StatefulWidget {
  const _RhCollaborateurShell();

  @override
  State<_RhCollaborateurShell> createState() => _RhCollaborateurShellState();
}

class _RhCollaborateurShellState extends State<_RhCollaborateurShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Mon profil'),
            Tab(text: 'Mon récap'),
            Tab(text: 'Mes demandes'),
            Tab(text: 'Présence'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RhProfilTab(),
          RhRecapScreen(embedded: true),
          _RhDemandesTab(),
          _RhPresenceTab(),
          _RhDocumentsTab(),
        ],
      ),
    );
  }
}

class _RhProfilTab extends StatefulWidget {
  const _RhProfilTab({this.collaborateurId});

  final String? collaborateurId;

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
    final id = widget.collaborateurId ?? auth.collaborateurId;
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
  const _RhDemandesTab({this.collaborateurId, this.executiveAll = false});

  final String? collaborateurId;
  final bool executiveAll;

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
      var filtered = list;
      if (widget.collaborateurId != null && !widget.executiveAll) {
        filtered = list
            .where((d) => d.idCollaborateur == widget.collaborateurId)
            .toList();
      }
      setState(() {
        _demandes = filtered;
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
                        final auth = context.watch<AuthProvider>();
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
                            trailing: auth.canValidateRhDemande &&
                                    d.statut == 'en_attente'
                                ? PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      try {
                                        await auth.api.patchDemandeRh(
                                          d.id,
                                          {'statut': v},
                                        );
                                        await _reload();
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => const [
                                      PopupMenuItem(
                                        value: 'approuve',
                                        child: Text('Approuver'),
                                      ),
                                      PopupMenuItem(
                                        value: 'rejete',
                                        child: Text('Rejeter'),
                                      ),
                                    ],
                                    child: Text(
                                      labelStatutDemande(d.statut),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : Column(
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

class _RhPresenceTab extends StatefulWidget {
  const _RhPresenceTab({this.collaborateurId});

  final String? collaborateurId;

  @override
  State<_RhPresenceTab> createState() => _RhPresenceTabState();
}

class _RhPresenceTabState extends State<_RhPresenceTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final collabId = widget.collaborateurId ??
          (auth.isPrivilegedStaff ? null : auth.collaborateurId);
      final rows = await auth.api.listPresence(collaborateurId: collabId);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'Aucune donnée de présence.',
          style: TextStyle(color: AromaColors.zinc500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rows.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = _rows[i];
        final date = '${r['date'] ?? ''}';
        final absence = r['absence'] == true;
        final retard = r['retard'] == true;
        return Card(
          child: ListTile(
            title: Text(formatDateFr(date)),
            subtitle: Text(
              absence
                  ? 'Absence'
                  : retard
                  ? 'Retard'
                  : 'Présent',
            ),
          ),
        );
      },
    );
  }
}

class _RhDocumentsTab extends StatefulWidget {
  const _RhDocumentsTab({this.collaborateurId});

  final String? collaborateurId;

  @override
  State<_RhDocumentsTab> createState() => _RhDocumentsTabState();
}

class _RhDocumentsTabState extends State<_RhDocumentsTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final collabId = widget.collaborateurId ??
        context.read<AuthProvider>().collaborateurId;
    if (collabId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final docs = await context.read<AuthProvider>().api.listDocumentRh(
        collabId,
      );
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_docs.isEmpty) {
      return const Center(
        child: Text(
          'Aucun document RH.',
          style: TextStyle(color: AromaColors.zinc500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final d = _docs[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('${d['type_document'] ?? d['nom_fichier'] ?? 'Document'}'),
            subtitle: Text(formatDateFr('${d['date_upload'] ?? ''}')),
          ),
        );
      },
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
