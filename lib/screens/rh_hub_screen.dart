import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tache.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/entity_scope_selector.dart';
import '../widgets/rh/rh_collaborateur_tile.dart';
import '../widgets/rh/rh_demandes_tab.dart';
import '../widgets/rh/rh_documents_tab.dart';
import '../widgets/rh/rh_presence_tab.dart';
import '../widgets/rh/rh_profil_tab.dart';
import '../widgets/rh/rh_ui.dart';
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

// ─── Direction ───────────────────────────────────────────────────────────────

class _RhExecutiveShell extends StatefulWidget {
  const _RhExecutiveShell({required this.onSelectCollaborateur});

  final ValueChanged<String> onSelectCollaborateur;

  @override
  State<_RhExecutiveShell> createState() => _RhExecutiveShellState();
}

class _RhExecutiveShellState extends State<_RhExecutiveShell> {
  String _currentTab = 'collabs';
  List<CollaborateurLite> _collaborateurs = [];
  String _search = '';
  bool _searchExpanded = false;
  bool _loading = true;
  final _searchFocus = FocusNode();

  static const _tabs = [
    RhTabConfig('collabs', 'Collaborateurs', Icons.people_outline_rounded),
    RhTabConfig('demandes', 'Demandes', Icons.inbox_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RhHeader(
              title: 'Espace RH',
              subtitle: 'Direction · ${_collaborateurs.length} collaborateurs',
              searchExpanded: _searchExpanded && _currentTab == 'collabs',
              searchFocus: _searchFocus,
              showSearch: _currentTab == 'collabs',
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
            ),
            const SizedBox(height: 8),
            RhTabPills(
              tabs: _tabs,
              selected: _currentTab,
              onSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _currentTab == 'demandes'
                  ? const RhDemandesTab(executiveAll: true)
                  : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: filtered.isEmpty
                          ? ListView(
                              children: const [
                                RhEmptyState(
                                  title: 'Aucun collaborateur',
                                  icon: Icons.people_outline_rounded,
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final c = filtered[i];
                                return RhCollaborateurTile(
                                  collaborateur: c,
                                  onTap: () =>
                                      widget.onSelectCollaborateur(c.id),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Détail collaborateur (direction) ────────────────────────────────────────

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

class _RhCollaborateurDetailShellState
    extends State<_RhCollaborateurDetailShell> {
  String _currentTab = 'profil';
  String _name = '';

  static const _tabs = [
    RhTabConfig('profil', 'Profil', Icons.person_outline_rounded),
    RhTabConfig('recap', 'Récap', Icons.insights_outlined),
    RhTabConfig('demandes', 'Demandes', Icons.inbox_outlined),
    RhTabConfig('presence', 'Présence', Icons.fingerprint_outlined),
    RhTabConfig('documents', 'Documents', Icons.folder_open_outlined),
  ];

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RhHeader(
              title: _name.isEmpty ? 'Collaborateur' : _name,
              subtitle: 'Fiche collaborateur',
              onBack: widget.onBack,
            ),
            const SizedBox(height: 8),
            RhTabPills(
              tabs: _tabs,
              selected: _currentTab,
              onSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() => switch (_currentTab) {
        'profil' => RhProfilTab(collaborateurId: widget.collaborateurId),
        'recap' => RhRecapScreen(
            embedded: true,
            collaborateurId: widget.collaborateurId,
          ),
        'demandes' => RhDemandesTab(collaborateurId: widget.collaborateurId),
        'presence' => RhPresenceTab(collaborateurId: widget.collaborateurId),
        'documents' => RhDocumentsTab(collaborateurId: widget.collaborateurId),
        _ => const SizedBox.shrink(),
      };
}

// ─── Collaborateur ───────────────────────────────────────────────────────────

class _RhCollaborateurShell extends StatefulWidget {
  const _RhCollaborateurShell();

  @override
  State<_RhCollaborateurShell> createState() => _RhCollaborateurShellState();
}

class _RhCollaborateurShellState extends State<_RhCollaborateurShell> {
  String _currentTab = 'profil';

  static const _tabs = [
    RhTabConfig('profil', 'Profil', Icons.person_outline_rounded),
    RhTabConfig('recap', 'Récap', Icons.insights_outlined),
    RhTabConfig('demandes', 'Demandes', Icons.inbox_outlined),
    RhTabConfig('presence', 'Présence', Icons.fingerprint_outlined),
    RhTabConfig('documents', 'Documents', Icons.folder_open_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RhHeader(
              title: 'Mon espace RH',
              subtitle: 'Profil, demandes et documents',
            ),
            const SizedBox(height: 8),
            RhTabPills(
              tabs: _tabs,
              selected: _currentTab,
              onSelected: (tab) => setState(() => _currentTab = tab),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() => switch (_currentTab) {
        'profil' => const RhProfilTab(),
        'recap' => const RhRecapScreen(embedded: true),
        'demandes' => const RhDemandesTab(),
        'presence' => const RhPresenceTab(),
        'documents' => const RhDocumentsTab(),
        _ => const SizedBox.shrink(),
      };
}

// ─── Header partagé ──────────────────────────────────────────────────────────

class _RhHeader extends StatelessWidget {
  const _RhHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.searchExpanded = false,
    this.searchFocus,
    this.showSearch = false,
    this.onSearchToggle,
    this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool searchExpanded;
  final FocusNode? searchFocus;
  final bool showSearch;
  final VoidCallback? onSearchToggle;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: RhUi.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ],
                ),
              ),
              const EntityScopeAppBarAction(),
              if (showSearch && onSearchToggle != null)
                IconButton(
                  onPressed: onSearchToggle,
                  icon: Icon(
                    searchExpanded
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                  ),
                ),
            ],
          ),
          if (searchExpanded && searchFocus != null && onSearchChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TextField(
                focusNode: searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un collaborateur…',
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
            ),
        ],
      ),
    );
  }
}
