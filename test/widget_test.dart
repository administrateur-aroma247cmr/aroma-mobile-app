import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aroma_jpc/app.dart';
import 'package:aroma_jpc/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('écran de connexion affiché sans session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: 'assets/env/app.env');
    final auth = AuthProvider();
    await auth.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const AromaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aroma JPC'), findsOneWidget);
    expect(find.textContaining('Connexion'), findsOneWidget);
  });
}
