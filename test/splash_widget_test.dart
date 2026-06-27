import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/features/auth/presentation/pages/splash_screen.dart';

void main() {
  testWidgets('Splash screen has account balance icon and title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );
    
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    expect(find.text('PocketLedger'), findsOneWidget);
  });
}
