// Create this as: lib/src/widgets/base_layout.dart
import 'package:flutter/material.dart';
import 'package:repairando_web/src/features/home/presentation/screens/shared_navigation.dart';
import 'package:repairando_web/src/theme/theme.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const BaseLayout({super.key, required this.child, this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: Column(
        children: [const SharedNavigation(), Expanded(child: child)],
      ),
    );
  }
}
