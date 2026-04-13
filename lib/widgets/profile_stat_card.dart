import 'package:flutter/material.dart';

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
