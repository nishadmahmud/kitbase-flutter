import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ToolDropzone extends StatefulWidget {
  final Function(List<PlatformFile>) onFiles;
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final String label;
  final String sublabel;
  final String supportedText;

  const ToolDropzone({
    super.key,
    required this.onFiles,
    required this.allowedExtensions,
    this.allowMultiple = true,
    required this.label,
    required this.sublabel,
    required this.supportedText,
  });

  @override
  State<ToolDropzone> createState() => _ToolDropzoneState();
}

class _ToolDropzoneState extends State<ToolDropzone> {
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: widget.allowMultiple,
      withData: true,
    );

    if (result != null) {
      widget.onFiles(result.files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = _isDragging
        ? theme.primaryColor
        : (isDark ? Colors.grey[700]! : Colors.grey[300]!);
    final backgroundColor = _isDragging
        ? theme.primaryColor.withValues(alpha: 0.1)
        : (isDark ? const Color(0xFF1f2937) : Colors.white);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        // Map XFile to PlatformFile for consistency with FilePicker
        final files = <PlatformFile>[];
        for (final xfile in details.files) {
          try {
            final bytes = await xfile.readAsBytes();
            final size = await xfile.length();
            files.add(PlatformFile(
              path: xfile.path,
              name: xfile.name,
              size: size,
              bytes: bytes,
            ));
          } catch (e) {
            debugPrint("Error reading dropped file: $e");
          }
        }

        // Basic extension filtering
        final filteredFiles = files.where((file) {
          final ext = file.name.split('.').last.toLowerCase();
          return widget.allowedExtensions.contains(ext);
        }).toList();

        if (filteredFiles.isNotEmpty) {
          widget.onFiles(filteredFiles);
        }
      },
      child: GestureDetector(
        onTap: _pickFiles,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 2,
              style: BorderStyle
                  .none, // We need a dashed package for true dashes, solid for now
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.cloudUpload,
                  size: 32,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sublabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.supportedText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
