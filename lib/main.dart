import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/app.env');
  final auth = AuthProvider();
  await auth.initialize();
  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const AromaApp(),
    ),
  );
}
