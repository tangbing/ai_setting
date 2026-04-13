import 'package:flutter/material.dart';

class DiscoverTabChip extends StatelessWidget {
  const DiscoverTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF111827) : const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
