import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/entity_scope_selector.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin, EntityScopeReloadMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  List<Tache> _tasks = [];
  List<CollaborateurLite> _collaborateurs = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
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
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<Tache>;
        _collaborateurs = results[1] as List<CollaborateurLite>;
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
    switch (tabIndex) {
      case 1:
        list = list.where((t) => t.isSelectionnee && !t.isTerminee);
        break;
      case 2:
        list = list.where((t) => t.isTerminee);
        break;
      default:
        list = list.where((t) => !t.isTerminee);
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
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: const [EntityScopeAppBarAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Sélectionnées'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher une tâche…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _reload)
                : TabBarView(
                    controller: _tabs,
                    children: List.generate(3, (i) {
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
                              onToggleDone: () => _toggleDone(t),
                              onToggleSelection: () => _toggleSelection(t),
                            );
                          },
                        ),
                      );
                    }),
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
    required this.onToggleDone,
    required this.onToggleSelection,
  });

  final Tache tache;
  final String assignee;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleSelection;

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
              'Assigné : $assignee',
              style: const TextStyle(
                fontSize: 13,
                color: AromaColors.zinc500,
              ),
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
