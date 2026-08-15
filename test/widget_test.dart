import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quetzalib/l10n/app_localizations.dart';
import 'package:quetzalib/screens/home_screen.dart';
import 'package:quetzalib/state/library_provider.dart';

void main() {
  testWidgets('Library screen shows empty state before any books are added',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LibraryProvider(),
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('My Library'), findsOneWidget);
    expect(find.textContaining('No books yet'), findsOneWidget);
  });
}
