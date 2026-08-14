import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openshelf/screens/home_screen.dart';
import 'package:openshelf/state/library_provider.dart';

void main() {
  testWidgets('Library screen shows empty state before any books are added',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LibraryProvider(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('My Library'), findsOneWidget);
    expect(find.textContaining('No books yet'), findsOneWidget);
  });
}
