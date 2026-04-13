import 'package:flutter/material.dart';

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    this.titleColor = const Color(0xFF111827),
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final Color titleColor;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      color: titleColor,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Color(0xFFC7C7CC),
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
          ),
      ],
    );
  }
}
