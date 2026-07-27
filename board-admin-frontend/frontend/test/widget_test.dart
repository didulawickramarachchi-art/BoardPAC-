import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('shows the landing screen before login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BoardAdminApp()));

    expect(find.text('BOARDPACK'), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('BOARDPACK'), findsNothing);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Sign In >'), findsOneWidget);
  });
}
