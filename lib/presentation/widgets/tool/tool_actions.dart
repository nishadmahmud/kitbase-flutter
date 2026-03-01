import 'package:flutter/material.dart';

class ToolActions extends StatelessWidget {
  final List<Widget> children;

  const ToolActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: children),
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback? onClick;
  final bool disabled;
  final bool loading;
  final IconData icon;
  final String label;

  const ActionButton({
    super.key,
    this.onClick,
    this.disabled = false,
    this.loading = false,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (disabled || loading) ? null : onClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.blue[600]?.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: disabled ? 0 : 2,
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
