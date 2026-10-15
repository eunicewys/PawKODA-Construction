// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pawkoda_fyp/main.dart';
import 'package:pawkoda_fyp/providers/user_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: We wrap in Provider because PawKODAApp needs it, 
    // and we skip Firebase initialization in this basic widget test.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const PawKODAApp(),
      ),
    );

    // Verify that the login screen is shown.
    expect(find.text('PawKODA'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
  });
}
