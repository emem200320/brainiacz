// lib/widgets/loading_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: CircleAvatar(radius: 20),
        title: Container(height: 10, color: Colors.white),
        subtitle: Container(height: 8, color: Colors.white),
      ),
    );
  }
}