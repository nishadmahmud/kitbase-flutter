import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'pdf_thumbnail.dart';

class ToolResult extends StatelessWidget {
  final bool success;
  final String message;
  final String? fileSize;
  final Uint8List? pdfBytes;
  final List<Widget>? actions;

  const ToolResult({
    super.key,
    required this.success,
    required this.message,
    this.fileSize,
    this.pdfBytes,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = success
        ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green[100]!)
        : (isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red[100]!);
    final bgColor = success
        ? (isDark ? Colors.green.withValues(alpha: 0.05) : Colors.green[50]!)
        : (isDark ? Colors.red.withValues(alpha: 0.05) : Colors.red[50]!);
    final textColor = success
        ? (isDark ? Colors.green[400]! : Colors.green[700]!)
        : (isDark ? Colors.red[400]! : Colors.red[700]!);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (success && pdfBytes != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PdfThumbnail(
                  bytes: pdfBytes!,
                  width: 80,
                  height: 112,
                  borderRadius: 8,
                ),
                if (fileSize != null) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Size:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        fileSize!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
          if (success && actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  actions![i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
