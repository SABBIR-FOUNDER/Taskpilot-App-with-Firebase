import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/task.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 40,
    this.white = false,
    this.wordmark = true,
  });
  final double size;
  final bool white;
  final bool wordmark;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/app_icon.png',
          width: size,
          height: size,
          semanticLabel: 'Taskpilot logo',
        ),
        if (wordmark) ...[
          const SizedBox(width: 12),
          Text(
            'Taskpilot',
            style: TextStyle(
              color: white ? Colors.white : Brand.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
        ],
      ],
    ),
  );
}

class PriorityPill extends StatelessWidget {
  const PriorityPill(this.priority, {super.key});
  final TaskPriority priority;
  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (priority) {
      TaskPriority.high => (
        'High priority',
        const Color(0xFFA8223A),
        const Color(0xFFFFEEF0),
      ),
      TaskPriority.medium => (
        'Medium',
        const Color(0xFF885C05),
        const Color(0xFFFFF5DB),
      ),
      TaskPriority.low => (
        'Low',
        const Color(0xFF096D58),
        const Color(0xFFE6F8F1),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void showNotice(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
  });
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}
