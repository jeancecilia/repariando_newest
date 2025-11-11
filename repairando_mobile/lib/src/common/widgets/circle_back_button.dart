import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFFFDF1E8),
        child: Icon(Icons.navigate_before, color: Colors.black),
      ),
    );
  }
}
