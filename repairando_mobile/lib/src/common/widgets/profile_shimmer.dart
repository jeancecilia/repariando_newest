import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class ProfileShimmer extends HookConsumerWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(context, ref) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 60, backgroundColor: Colors.white),
          const SizedBox(height: 16),
          Container(height: 20, width: 150, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 14, width: 200, color: Colors.white),
        ],
      ),
    );
  }
}
