import 'package:flutter/material.dart';
import 'custom_back_button.dart';

class CustomHeaderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Color baseColor;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomHeaderAppBar({
    super.key,
    required this.title,
    required this.baseColor,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // The padding logic ensures the content stays below the system status bar,
    // mimicking a standard AppBar layout but with custom decoration.
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, baseColor.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            CustomBackButton(
              onPressed: () => Navigator.pop(context),
              iconColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    // The preferred size needs to account for the status bar padding plus our custom heights
    return const Size.fromHeight(kToolbarHeight + 60);
  }
}
