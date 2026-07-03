import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_lite.dart';
import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/format_utils.dart';
import '../utils/task_rules.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/modern_select_field.dart';
import '../widgets/tasks/task_card_modern.dart';
import '../widgets/tasks/task_detail_sheet.dart';
import '../widgets/tasks/task_ui.dart';
import '../widgets/tasks/tasks_calendar_tab.dart';
import '../widgets/tasks_recap_tab.dart';

enum _TaskScreenTab { active, starred, history, calendar, recap }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<Tache> _tasks = [];
  List<CollaborateurLite> _collaborateurs = [];
  List<ClientLite> _clients = [];
  String _search = '';
  bool _searchExpanded = false;
  final _searchFocus = FocusNode();
  _TaskScreenTab _currentTab = _TaskScreenTab.active;
  String _recapMonth = currentMonthIso();
  String? _recapCollabFilter;
  String? _executiveCollabFilter;

  List<_TabConfig> _visibleTabs(AuthProvider auth) => [
        _TabConfig(
          _TaskScreenTab.active,
          'En cours',
          Icons.play_circle_outline_rounded,
          _tasks.where(taskMatchesActiveList).length,
        ),
        _TabConfig(
          _TaskScreenTab.starred,
          'Sélectionnées',
          Icons.bookmark_outline_rounded,
          _stats.starred,
        ),
        _TabConfig(
          _TaskScreenTab.history,
          'Historique',
          Icons.history_rounded,
          _tasks.where(taskMatchesHistoryList).length,
        ),
        const _TabConfig(
          _TaskScreenTab.calendar,
          'Mon calendrier',
          Icons.calendar_month_outlined,
          null,
        ),
        if (auth.canViewCollaborateurRecaps)
          const _TabConfig(
            _TaskScreenTab.recap,
            'Mon récapitulatif',
            Icons.insights_outlined,
            null,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
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
      for (final c in _collaborateurs) {
        if (c.id == id) {
          names.add(c.fullName);
          break;
        }
      }
    }
    return names.isEmpty ? '—' : names.join(', ');
  }

  List<Tache> _filteredForTab(_TaskScreenTab tab) {
    Iterable<Tache> list = _tasks;
    switch (tab) {
      case _TaskScreenTab.starred:
        list = list.where(isSelectedRappelTask);
        break;
      case _TaskScreenTab.history:
        list = list.where(taskMatchesHistoryList);
        break;
      case _TaskScreenTab.calendar:
      case _TaskScreenTab.recap:
        return const [];
      case _TaskScreenTab.active:
        list = list.where(taskMatchesActiveList);
    }
    final auth = context.read<AuthProvider>();
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
            (t.description ?? '').toLowerCase().contains(q) ||
            _clientLabel(t).toLowerCase().contains(q),
      );
    }
    final rows = list.toList();
    switch (tab) {
      case _TaskScreenTab.history:
        rows.sort((a, b) => historyClosureSortMs(b).compareTo(historyClosureSortMs(a)));
      case _TaskScreenTab.starred:
        rows.sort(
          (a, b) => selectedRappelSortMs(b).compareTo(selectedRappelSortMs(a)),
        );
      case _TaskScreenTab.active:
        rows.sort((a, b) {
          final oa = TaskUi.isOverdue(a);
          final ob = TaskUi.isOverdue(b);
          if (oa != ob) return oa ? -1 : 1;
          return (a.dateButoire ?? '').compareTo(b.dateButoire ?? '');
        });
      case _TaskScreenTab.calendar:
      case _TaskScreenTab.recap:
        break;
    }
    return rows;
  }

  ({int active, int overdue, int starred}) get _stats {
    final activeTasks = _tasks.where(taskMatchesActiveList).toList();
    final active = activeTasks.length;
    final overdue = activeTasks.where(TaskUi.isOverdue).length;
    final starred = _tasks.where(isSelectedRappelTask).length;
    return (active: active, overdue: overdue, starred: starred);
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
      final next = t.isTerminee ? statutEnCours : statutTermine;
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
    final ok = await showModernBottomSheet<bool>(
      context: context,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la tâche ?'),
        content: Text(
          '« ${t.nomTache} » sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
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

  void _openDetail(Tache t) {
    final auth = context.read<AuthProvider>();
    showTaskDetailSheet(
      context,
      tache: t,
      client: _clientLabel(t),
      assignee: _assigneeLabel(t),
      superviseur: _superviseurLabel(t),
      canEdit: auth.canEditTache,
      canDelete: auth.canDeleteTache,
      onEdit: () => _openForm(tache: t),
      onDelete: () => _deleteTask(t),
      onToggleDone: () => _toggleDone(t),
      onToggleSelection: () => _toggleSelection(t),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    final auth = context.watch<AuthProvider>();
    final stats = _stats;
    final tabs = _visibleTabs(auth);
    if (!tabs.any((t) => t.id == _currentTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentTab = _TaskScreenTab.active);
      });
    }
    final isListTab = _currentTab == _TaskScreenTab.active ||
        _currentTab == _TaskScreenTab.starred ||
        _currentTab == _TaskScreenTab.history;

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _reload)
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: _TasksHeader(
                      embedded: widget.embedded,
                      compact: !isListTab,
                      searchExpanded: _searchExpanded,
                      searchFocus: _searchFocus,
                      onSearchToggle: () {
                        setState(() {
                          _searchExpanded = !_searchExpanded;
                          if (_searchExpanded) {
                            _searchFocus.requestFocus();
                          } else {
                            _search = '';
                            _searchFocus.unfocus();
                          }
                        });
                      },
                      onSearchChanged: (v) => setState(() => _search = v),
                      stats: stats,
                    ),
                  ),
                  if (isListTab &&
                      auth.canViewAllTaches &&
                      _collaborateurs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: _CollaborateurFilter(
                          collaborateurs: _collaborateurs,
                          value: _executiveCollabFilter,
                          onChanged: (v) =>
                              setState(() => _executiveCollabFilter = v),
                        ),
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedTabBarDelegate(
                      child: _TabPills(
                        tabs: tabs,
                        selected: _currentTab,
                        onSelected: (tab) => setState(() => _currentTab = tab),
                      ),
                    ),
                  ),
                ],
                body: _currentTab == _TaskScreenTab.calendar
                    ? TasksCalendarTab(
                        tasks: _tasks,
                        showAllTasks: auth.canViewAllTaches,
                        collaborateurId: auth.collaborateurId,
                        onTaskTap: _openDetail,
                      )
                    : _currentTab == _TaskScreenTab.recap
                    ? TasksRecapTab(
                        tasks: _tasks,
                        collaborateurs: _collaborateurs,
                        currentCollaborateurId: auth.collaborateurId,
                        isExecutive: auth.isExecutive,
                        monthKey: _recapMonth,
                        onMonthChanged: (m) =>
                            setState(() => _recapMonth = m),
                        selectedCollaborateurId: _recapCollabFilter,
                        onCollaborateurChanged: (v) =>
                            setState(() => _recapCollabFilter = v),
                      )
                    : _TaskList(
                        items: _filteredForTab(_currentTab),
                        tab: _currentTab,
                        canCreate: auth.canCreateTache,
                        clientLabel: _clientLabel,
                        assigneeLabel: _assigneeLabel,
                        superviseurLabel: _superviseurLabel,
                        onRefresh: _reload,
                        onTap: _openDetail,
                        onToggleDone: _toggleDone,
                        onToggleSelection: _toggleSelection,
                        onCreate: () => _openForm(),
                      ),
              ),
      ),
      floatingActionButton: auth.canCreateTache && isListTab
          ? Container(
              decoration: BoxDecoration(
                gradient: TaskUi.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: TaskUi.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'fab-tasks-new',
                onPressed: () => _openForm(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Nouvelle tâche',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _TabConfig {
  const _TabConfig(this.id, this.label, this.icon, this.count);
  final _TaskScreenTab id;
  final String label;
  final IconData icon;
  final int? count;
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.embedded,
    required this.compact,
    required this.searchExpanded,
    required this.searchFocus,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.stats,
  });

  final bool embedded;
  final bool compact;
  final bool searchExpanded;
  final FocusNode searchFocus;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final ({int active, int overdue, int starred}) stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, embedded ? 4 : 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes tâches',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.active} en cours'
                        '${stats.overdue > 0 ? ' · ${stats.overdue} en retard' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                const EntityScopeAppBarAction(),
                if (!compact)
                  IconButton(
                    onPressed: onSearchToggle,
                    icon: Icon(
                      searchExpanded ? Icons.close_rounded : Icons.search_rounded,
                    ),
                  ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${stats.active} en cours'
                    '${stats.overdue > 0 ? ' · ${stats.overdue} en retard' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AromaColors.zinc500,
                    ),
                  ),
                ),
                if (!compact)
                  IconButton(
                    onPressed: onSearchToggle,
                    icon: Icon(
                      searchExpanded ? Icons.close_rounded : Icons.search_rounded,
                    ),
                  ),
              ],
            ),
          if (!compact && searchExpanded) ...[
            const SizedBox(height: 8),
            TextField(
              focusNode: searchFocus,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tâche, client, description…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AromaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _StatPill(
                  label: 'Actives',
                  value: '${stats.active}',
                  color: TaskUi.accent,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Retard',
                  value: '${stats.overdue}',
                  color: stats.overdue > 0
                      ? const Color(0xFFDC2626)
                      : AromaColors.zinc500,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Sélection',
                  value: '${stats.starred}',
                  color: const Color(0xFF059669),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AromaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AromaColors.zinc500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPills extends StatefulWidget {
  const _TabPills({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<_TabConfig> tabs;
  final _TaskScreenTab selected;
  final ValueChanged<_TaskScreenTab> onSelected;

  @override
  State<_TabPills> createState() => _TabPillsState();
}

class _TabPillsState extends State<_TabPills> {
  final _keys = <_TaskScreenTab, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(_TabPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureKeys();
    if (oldWidget.selected != widget.selected ||
        oldWidget.tabs.length != widget.tabs.length) {
      _scrollToSelected();
    }
  }

  void _ensureKeys() {
    for (final tab in widget.tabs) {
      _keys.putIfAbsent(tab.id, GlobalKey.new);
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _keys[widget.selected];
      final ctx = key?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.canvas,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tab = widget.tabs[i];
              final isSelected = widget.selected == tab.id;
              final count = tab.count;
              return KeyedSubtree(
                key: _keys[tab.id],
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSelected(tab.id),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? TaskUi.gradient : null,
                        color: isSelected ? null : AromaColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE4E4E7),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: TaskUi.accent.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AromaColors.zinc500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AromaColors.zinc800,
                            ),
                          ),
                          if (count != null && count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AromaColors.zinc100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AromaColors.zinc800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate({required this.child});

  final Widget child;

  static const double _tabBarHeight = 52;

  @override
  double get minExtent => _tabBarHeight;

  @override
  double get maxExtent => _tabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AromaColors.canvas,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      child != oldDelegate.child;
}

class _CollaborateurFilter extends StatelessWidget {
  const _CollaborateurFilter({
    required this.collaborateurs,
    required this.value,
    required this.onChanged,
  });

  final List<CollaborateurLite> collaborateurs;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ModernSelectField<String?>(
      label: 'Filtrer par collaborateur',
      hint: 'Tous les collaborateurs',
      leadingIcon: Icons.person_search_rounded,
      allowClear: true,
      clearLabel: 'Tous les collaborateurs',
      value: value,
      options: collaborateurs
          .map(
            (c) => ModernSelectOption<String?>(
              value: c.id,
              label: c.fullName,
              icon: Icons.person_rounded,
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.items,
    required this.tab,
    required this.canCreate,
    required this.clientLabel,
    required this.assigneeLabel,
    required this.superviseurLabel,
    required this.onRefresh,
    required this.onTap,
    required this.onToggleDone,
    required this.onToggleSelection,
    required this.onCreate,
  });

  final List<Tache> items;
  final _TaskScreenTab tab;
  final bool canCreate;
  final String Function(Tache) clientLabel;
  final String Function(Tache) assigneeLabel;
  final String Function(Tache) superviseurLabel;
  final Future<void> Function() onRefresh;
  final void Function(Tache) onTap;
  final Future<void> Function(Tache) onToggleDone;
  final Future<void> Function(Tache) onToggleSelection;
  final VoidCallback onCreate;

  String get _emptyTitle => switch (tab) {
        _TaskScreenTab.starred => 'Aucune tâche sélectionnée',
        _TaskScreenTab.history => 'Historique vide',
        _ => 'Aucune tâche en cours',
      };

  String? get _emptySubtitle => switch (tab) {
        _TaskScreenTab.active when canCreate =>
          'Créez votre première tâche pour commencer.',
        _TaskScreenTab.starred =>
          'Marquez des tâches avec le signet pour les retrouver ici.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: TaskUi.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: TaskEmptyState(
                title: _emptyTitle,
                subtitle: _emptySubtitle,
                actionLabel: tab == _TaskScreenTab.active && canCreate
                    ? 'Nouvelle tâche'
                    : null,
                onAction: tab == _TaskScreenTab.active && canCreate
                    ? onCreate
                    : null,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TaskUi.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final t = items[index];
          return TaskCardModern(
            tache: t,
            client: clientLabel(t),
            assignee: assigneeLabel(t),
            superviseur: superviseurLabel(t),
            onTap: () => onTap(t),
            onToggleDone: () => onToggleDone(t),
            onToggleSelection: () => onToggleSelection(t),
          );
        },
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
            const Icon(Icons.cloud_off_rounded, size: 48, color: AromaColors.zinc500),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
