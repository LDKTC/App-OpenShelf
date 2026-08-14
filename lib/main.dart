import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/library_provider.dart';
import 'theme.dart';

void main() {
  runApp(const OpenShelfApp());
}

class OpenShelfApp extends StatelessWidget {
  const OpenShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProvider()..loadAll(),
      child: MaterialApp(
        title: 'OpenShelf',
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
