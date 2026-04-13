import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/auth_flow_shell.dart';
import 'screens/main_shell.dart';
import 'theme/aroma_theme.dart';

class AromaApp extends StatelessWidget {
  const AromaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aroma JPC',
      theme: buildAromaTheme(),
      themeMode: ThemeMode.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.initialized) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFFFF),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) {
          return const MainShell();
        }
        return const AuthFlowShell();
      },
    );
  }
}
