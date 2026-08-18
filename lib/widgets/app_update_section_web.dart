import 'package:flutter/widgets.dart';

/// Web: there's no APK to sideload-update, so this section is simply absent
/// — a browser tab always serves the latest deployed build on reload.
class AppUpdateSection extends StatelessWidget {
  const AppUpdateSection({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
