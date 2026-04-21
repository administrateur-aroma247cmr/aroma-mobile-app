import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/aroma_logo.dart';
import 'galerie_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _logout() async {
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
  }

  static Widget _drawerIconHome({required bool selected}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AromaColors.zinc100 : AromaColors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AromaColors.zinc200 : const Color(0x14000000),
        ),
      ),
      child: Icon(
        Icons.home_rounded,
        size: 22,
        color: selected ? AromaColors.primary : AromaColors.zinc500,
      ),
    );
  }

  static Widget _drawerIconGalerie({required bool selected}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  AromaColors.galerieGradientStart,
                  AromaColors.galerieGradientEnd,
                ]
              : [
                  AromaColors.galerieGradientStart.withValues(alpha: 0.85),
                  AromaColors.galerieGradientEnd.withValues(alpha: 0.85),
                ],
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AromaColors.galerieGradientEnd.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: const Icon(Icons.image_rounded, size: 22, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _index == 0 ? 'Mon tableau de bord' : 'Ma galerie';

    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(title: Text(title)),
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: _drawerIconHome(selected: _index == 0),
                      title: const Text('Mon accueil'),
                      selected: _index == 0,
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
                        setState(() => _index = 0);
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: _drawerIconGalerie(selected: _index == 1),
                      title: const Text('Ma galerie'),
                      selected: _index == 1,
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
                        setState(() => _index = 1);
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
        index: _index,
        sizing: StackFit.expand,
        children: [
          HomeScreen(
            key: const PageStorageKey<String>('home'),
            onOpenGalerie: () => setState(() => _index = 1),
          ),
          const GalerieScreen(
            key: PageStorageKey<String>('galerie'),
            embedded: true,
          ),
        ],
      ),
    );
  }
}
