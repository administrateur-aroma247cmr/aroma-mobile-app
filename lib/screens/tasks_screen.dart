import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';
import '../models/client_lite.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/tasks_recap_tab.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin, EntityScopeReloadMixin {
  TabController? _tabs;
  bool _loading = true;
  String? _error;
  List<Tache> _tasks = [];
  List<CollaborateurLite> _collaborateurs = [];
  List<ClientLite> _clients = [];
  String _search = '';
  String _recapMonth = currentMonthIso();
  String? _recapCollabFilter;
  String? _executiveCollabFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTabs());
  }

  void _initTabs() {
    if (!mounted) return;
    final len = context.read<AuthProvider>().canViewCollaborateurRecaps ? 5 : 4;
    _tabs = TabController(length: len, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final results = await Future.wait([
        api.listTaches(),
        api.listCollaborateursLite(),
        api.listClientsLite(),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<Tache>;
        _collaborateurs = results[1] as List<CollaborateurLite>;
        _clients = results[2] as List<ClientLite>;
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

  String _clientLabel(Tache t) {
    if (t.clientId == null) return '—';
    for (final c in _clients) {
      if (c.id == t.clientId) return c.nomClient;
    }
    return '—';
  }

  String _superviseurLabel(Tache t) {
    if (t.superviseurId == null) return '—';
    for (final c in _collaborateurs) {
      if (c.id == t.superviseurId) return c.fullName;
    }
    return '—';
  }

  String _assigneeLabel(Tache t) {
    final ids = t.collaborateurIds.isNotEmpty
        ? t.collaborateurIds
        : (t.collaborateurId != null ? [t.collaborateurId!] : <String>[]);
    if (ids.isEmpty) return '—';
    final names = <String>[];
    for (final id in ids) {
      CollaborateurLite? match;
      for (final c in _collaborateurs) {
        if (c.id == id) {
          match = c;
          break;
        }
      }
      if (match != null) names.add(match.fullName);
    }
    return names.isEmpty ? '—' : names.join(', ');
  }

  List<Tache> _filtered(int tabIndex) {
    Iterable<Tache> list = _tasks;
    final auth = context.read<AuthProvider>();
    switch (tabIndex) {
      case 1:
        list = list.where((t) => t.isSelectionnee && !t.isTerminee);
        break;
      case 2:
        list = list.where((t) => t.isTerminee);
        break;
      case 3:
        list = list.where((t) => t.isTerminee);
        break;
      case 4:
        return const [];
      default:
        list = list.where((t) => !t.isTerminee);
    }
    if (_executiveCollabFilter != null && auth.canViewAllTaches) {
      final id = _executiveCollabFilter!;
      list = list.where((t) {
        final ids = t.collaborateurIds.isNotEmpty
            ? t.collaborateurIds
            : (t.collaborateurId != null ? [t.collaborateurId!] : <String>[]);
        return ids.contains(id) || t.superviseurId == id;
      });
    }
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (t) =>
            t.nomTache.toLowerCase().contains(q) ||
            (t.description ?? '').toLowerCase().contains(q),
      );
    }
    return list.toList()
      ..sort((a, b) {
        final da = a.dateButoire ?? '';
        final db = b.dateButoire ?? '';
        return da.compareTo(db);
      });
  }

  Future<void> _toggleDone(Tache t) async {
    final auth = context.read<AuthProvider>();
    if (!auth.canModify('tasks') && !auth.isPrivilegedStaff) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification non autorisée.')),
      );
      return;
    }
    try {
      final next = t.isTerminee ? 'En cours' : 'Terminé';
      final body = <String, dynamic>{'statut': next};
      if (next == 'Terminé') {
        final now = DateTime.now();
        body['date_terminee'] =
            '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
      } else {
        body['date_terminee'] = null;
      }
      await auth.api.patchTache(t.id, body);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openForm({Tache? tache}) async {
    final auth = context.read<AuthProvider>();
    if (tache == null && !auth.canCreateTache) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Création non autorisée.')),
      );
      return;
    }
    if (tache != null && !auth.canEditTache) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification non autorisée.')),
      );
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskFormSheet(
        tache: tache,
        collaborateurs: _collaborateurs,
        clients: _clients,
      ),
    );
    if (ok == true) await _reload();
  }

  Future<void> _deleteTask(Tache t) async {
    final auth = context.read<AuthProvider>();
    if (!auth.canDeleteTache) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await auth.api.deleteTache(t.id);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _toggleSelection(Tache t) async {
    try {
      final auth = context.read<AuthProvider>();
      final next = !t.isSelectionnee;
      final body = <String, dynamic>{'est_selectionnee': next};
      if (next) {
        final now = DateTime.now();
        body['date_selection'] =
            '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
      } else {
        body['date_selection'] = null;
      }
      await auth.api.patchTache(t.id, body);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: const [EntityScopeAppBarAction()],
        bottom: _tabs == null
            ? null
            : TabBar(
                controller: _tabs!,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'En cours'),
                  const Tab(text: 'Sélectionnées'),
                  const Tab(text: 'Terminées'),
                  const Tab(text: 'Historique'),
                  if (auth.canViewCollaborateurRecaps)
                    const Tab(text: 'Mon récap'),
                ],
              ),
      ),
      floatingActionButton: auth.canCreateTache
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle tâche'),
            )
          : null,
      body: Column(
        children: [
          if (_tabs != null && _tabs!.index < 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une tâche…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  if (auth.canViewAllTaches && _collaborateurs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par collaborateur',
                        isDense: true,
                      ),
                      value: _executiveCollabFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._collaborateurs.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.fullName),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _executiveCollabFilter = v),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _tabs == null || _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _reload)
                : TabBarView(
                    controller: _tabs!,
                    children: [
                      ...List.generate(4, (i) {
                        final items = _filtered(i);
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aucune tâche.',
                              style: TextStyle(color: AromaColors.zinc500),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final t = items[index];
                              return _TaskCard(
                                tache: t,
                                assignee: _assigneeLabel(t),
                                client: _clientLabel(t),
                                superviseur: _superviseurLabel(t),
                                canEdit: auth.canEditTache,
                                canDelete: auth.canDeleteTache,
                                onToggleDone: () => _toggleDone(t),
                                onToggleSelection: () => _toggleSelection(t),
                                onEdit: () => _openForm(tache: t),
                                onDelete: () => _deleteTask(t),
                              );
                            },
                          ),
                        );
                      }),
                      if (auth.canViewCollaborateurRecaps)
                        TasksRecapTab(
                          tasks: _tasks,
                          collaborateurs: _collaborateurs,
                          currentCollaborateurId: auth.collaborateurId,
                          isExecutive: auth.canViewAllTaches,
                          monthKey: _recapMonth,
                          onMonthChanged: (m) => setState(() => _recapMonth = m),
                          selectedCollaborateurId: _recapCollabFilter,
                          onCollaborateurChanged: (v) =>
                              setState(() => _recapCollabFilter = v),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.tache,
    required this.assignee,
    required this.client,
    required this.superviseur,
    required this.canEdit,
    required this.canDelete,
    required this.onToggleDone,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onDelete,
  });

  final Tache tache;
  final String assignee;
  final String client;
  final String superviseur;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _priorityColor() {
    return switch (tache.priorite) {
      'Haute' => Colors.red.shade700,
      'Basse' => Colors.blue.shade600,
      _ => Colors.orange.shade700,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tache.nomTache,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tache.isSelectionnee
                      ? 'Retirer des sélectionnées'
                      : 'Ajouter aux sélectionnées',
                  onPressed: onToggleSelection,
                  icon: Icon(
                    tache.isSelectionnee
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: tache.isSelectionnee
                        ? Colors.amber.shade700
                        : AromaColors.zinc500,
                  ),
                ),
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      if (canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier'),
                        ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                    ],
                  ),
              ],
            ),
            if ((tache.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tache.description!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AromaColors.zinc500),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  label: tache.priorite ?? 'Moyenne',
                  color: _priorityColor(),
                ),
                _Chip(
                  label: formatDateFr(tache.dateButoire),
                  color: AromaColors.zinc800,
                ),
                if (tache.categorie != null && tache.categorie!.isNotEmpty)
                  _Chip(label: tache.categorie!, color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Client : $client',
              style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
            ),
            Text(
              'Assigné à : $assignee',
              style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
            ),
            Text(
              'Superviseur : $superviseur',
              style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onToggleDone,
                icon: Icon(
                  tache.isTerminee
                      ? Icons.replay_rounded
                      : Icons.check_circle_outline,
                ),
                label: Text(tache.isTerminee ? 'Rouvrir' : 'Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
