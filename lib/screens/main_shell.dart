import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_modules.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/aroma_logo.dart';
import '../widgets/entity_scope_selector.dart';
import 'analytics_screen.dart';
import 'caisse_screen.dart';
import 'compta_hub_screen.dart';
import 'galerie_screen.dart';
import 'home_screen.dart';
import 'interventions_hub_screen.dart';
import 'ma_validation_screen.dart';
import 'rh_hub_screen.dart';
import 'tasks_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppModuleId _currentModule = AppModuleId.home;

  Future<void> _logout() async {
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
  }

  void _selectModule(AppModuleId module) {
    setState(() => _currentModule = module);
  }

  Widget _pageFor(AppModuleId id, AuthProvider auth) {
    final entityKey = auth.currentEntityCode;
    switch (id) {
      case AppModuleId.home:
        return HomeScreen(onOpenModule: _selectModule);
      case AppModuleId.analytics:
        return AnalyticsScreen(
          key: ValueKey('analytics-$entityKey'),
          embedded: true,
        );
      case AppModuleId.tasks:
        return TasksScreen(key: ValueKey('tasks-$entityKey'), embedded: true);
      case AppModuleId.interventions:
        return InterventionsHubScreen(
          key: ValueKey('interventions-$entityKey'),
          embedded: true,
        );
      case AppModuleId.rh:
        return RhHubScreen(key: ValueKey('rh-$entityKey'), embedded: true);
      case AppModuleId.compta:
        return ComptaHubScreen(
          key: ValueKey('compta-$entityKey'),
          embedded: true,
        );
      case AppModuleId.caisse:
        return CaisseScreen(
          key: ValueKey('caisse-$entityKey'),
          embedded: true,
        );
      case AppModuleId.validation:
        return MaValidationScreen(
          key: ValueKey('validation-$entityKey'),
          embedded: true,
        );
      case AppModuleId.galerie:
        return GalerieScreen(
          key: ValueKey('galerie-$entityKey'),
          embedded: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final modules = visibleAppModules(auth);
    if (!modules.any((m) => m.id == _currentModule)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentModule = AppModuleId.home);
      });
    }
    final currentEntry = appModuleById(_currentModule);
    final title = currentEntry?.title ?? 'Mon tableau de bord';

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: Text(title),
        actions: const [EntityScopeAppBarAction()],
      ),
      drawer: Drawer(
        backgroundColor: AromaColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
                ),
                child: Row(
                  children: [
                    const AromaLogo(height: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aroma JPC',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (auth.showEntitySelector) const EntityScopeSelector(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final module in modules)
                      ListTile(
                        leading: appModuleDrawerIcon(
                          module,
                          selected: _currentModule == module.id,
                        ),
                        title: Text(module.title),
                        selected: _currentModule == module.id,
                        selectedTileColor: AromaColors.zinc100.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onTap: () {
                          setState(() => _currentModule = module.id);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  child: const Icon(Icons.logout_rounded, size: 22),
                ),
                title: Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.red.shade800),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: () {
          final i = modules.indexWhere((m) => m.id == _currentModule);
          return i >= 0 ? i : 0;
        }(),
        sizing: StackFit.expand,
        children: [
          for (final module in modules)
            _pageFor(module.id, auth),
        ],
      ),
    );
  }
}
