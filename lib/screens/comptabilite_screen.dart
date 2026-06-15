import 'package:flutter/material.dart';

import '../theme/aroma_theme.dart';
import '../widgets/entity_scope_selector.dart';
import 'recouvrement_screen.dart';

/// Module comptabilité — le recouvrement est intégré ici, comme sur le CRM web.
class ComptabiliteScreen extends StatelessWidget {
  const ComptabiliteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AromaColors.canvas,
      appBar: AppBar(
        title: const Text('Ma comptabilité'),
        actions: const [EntityScopeAppBarAction()],
      ),
      body: const RecouvrementScreen(embedded: true),
    );
  }
}
