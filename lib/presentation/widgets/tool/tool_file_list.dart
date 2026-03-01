import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'pdf_thumbnail.dart';

class ToolFileList extends StatelessWidget {
  final List<PlatformFile> files;
  final Function(int) onRemove;
  final VoidCallback onClearAll;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const ToolFileList({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onClearAll,
    this.onReorder,
  });

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF1f2937) : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827).withValues(alpha: 0.5)
                  : Colors.grey[50]!.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1f2937) : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${files.length} file${files.length != 1 ? 's' : ''} added',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // List
          if (onReorder != null)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              onReorder: onReorder!,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final file = files[index];
                return Container(
                  key: ObjectKey(file),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: index == files.length - 1
                            ? Colors.transparent
                            : (isDark
                                  ? const Color(0xFF1f2937)
                                  : Colors.grey[100]!),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            LucideIcons.gripVertical,
                            size: 16,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (file.bytes != null)
                          PdfThumbnail(
                            bytes: file.bytes!,
                            width: 32,
                            height: 48,
                            borderRadius: 4,
                          )
                        else
                          Icon(
                            LucideIcons.fileText,
                            size: 24,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            file.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatBytes(file.size),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () => onRemove(index),
                          color: Colors.grey[400],
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF1f2937) : Colors.grey[100],
              ),
              itemBuilder: (context, index) {
                final file = files[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      if (file.bytes != null)
                        PdfThumbnail(
                          bytes: file.bytes!,
                          width: 32,
                          height: 48,
                          borderRadius: 4,
                        )
                      else
                        Icon(
                          LucideIcons.fileText,
                          size: 24,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          file.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[200] : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatBytes(file.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => onRemove(index),
                        color: Colors.grey[400],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
