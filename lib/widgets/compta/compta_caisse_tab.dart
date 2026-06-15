import 'package:flutter/material.dart';

import '../../screens/caisse_screen.dart';

class ComptaCaisseTab extends StatelessWidget {
  const ComptaCaisseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaisseScreen(embedded: true);
  }
}
