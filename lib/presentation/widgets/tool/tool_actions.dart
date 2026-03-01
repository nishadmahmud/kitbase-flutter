import 'package:flutter/material.dart';

enum ActionButtonVariant { primary, secondary }

class ToolActions extends StatelessWidget {
  final List<Widget> children;

  const ToolActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: children,
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback? onClick;
  final bool disabled;
  final bool loading;
  final IconData icon;
  final String label;
  final bool fullWidth;
  final ActionButtonVariant variant;
  final Color? color;

  const ActionButton({
    super.key,
    this.onClick,
    this.disabled = false,
    this.loading = false,
    required this.icon,
    required this.label,
    this.fullWidth = false,
    this.variant = ActionButtonVariant.primary,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = color ?? Colors.blue[600]!;

    final btnStyle = variant == ActionButtonVariant.primary
        ? ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: disabled ? 0 : 2,
          )
        : ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            foregroundColor: isDark ? Colors.white : Colors.grey[900],
            disabledBackgroundColor:
                (isDark ? Colors.grey[800] : Colors.grey[200])!.withValues(
                  alpha: 0.5,
                ),
            disabledForegroundColor: (isDark ? Colors.white : Colors.grey[900])!
                .withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          );

    final button = ElevatedButton.icon(
      onPressed: (disabled || loading) ? null : onClick,
      style: btnStyle,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  variant == ActionButtonVariant.primary
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
