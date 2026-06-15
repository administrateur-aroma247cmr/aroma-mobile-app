import 'package:flutter/material.dart';

import '../../screens/recouvrement_screen.dart';

class ComptaRecouvrementTab extends StatelessWidget {
  const ComptaRecouvrementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecouvrementScreen(embedded: true);
  }
}
