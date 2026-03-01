import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:kitbase_flutter/presentation/widgets/tool/tool_header.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_dropzone.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_actions.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_sidebar.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_result.dart';
import 'package:kitbase_flutter/core/constants/tools_registry.dart';

// ──────────────────────────────────────────────
// Isolate: Structural PDF optimization
// Mirrors the web version's approach: strip metadata,
// remove unused objects, and save with best compression.
// ──────────────────────────────────────────────
Future<Uint8List> _compressPdfIsolate(Uint8List inputBytes) async {
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  // Apply maximum compression to internal streams
  document.compressionLevel = PdfCompressionLevel.best;

  // Strip all metadata
  document.documentInformation.title = '';
  document.documentInformation.author = '';
  document.documentInformation.subject = '';
  document.documentInformation.keywords = '';
  document.documentInformation.creator = '';
  document.documentInformation.producer = '';
  document.documentInformation.modificationDate = DateTime(1970);
  document.documentInformation.creationDate = DateTime(1970);

  // Remove bookmarks
  if (document.bookmarks.count > 0) {
    document.bookmarks.clear();
  }

  // Remove annotations from every page
  for (int i = 0; i < document.pages.count; i++) {
    final page = document.pages[i];
    while (page.annotations.count > 0) {
      page.annotations.remove(page.annotations[0]);
    }
  }

  // Remove form fields
  try {
    if (document.form.fields.count > 0) {
      document.form.fields.clear();
    }
    document.form.flattenAllFields();
  } catch (_) {
    // Document may not have a form, that's fine
  }

  // Save the optimized document
  final bytes = await document.save();
  document.dispose();

  return Uint8List.fromList(bytes);
}

// ──────────────────────────────────────────────
// Main Widget
// ──────────────────────────────────────────────
class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  PlatformFile? _file;
  Uint8List? _fileBytes;

  bool _isProcessing = false;
  Uint8List? _resultBytes;
  String? _error;

  // ──────────────────────────────────
  // File handling
  // ──────────────────────────────────
  Future<void> _handleFiles(List<PlatformFile> newFiles) async {
    if (newFiles.isEmpty) return;
    final f = newFiles.first;

    Uint8List bytes;
    if (f.bytes != null) {
      bytes = f.bytes!;
    } else if (f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    } else {
      return;
    }

    setState(() {
      _file = f;
      _fileBytes = bytes;
      _resultBytes = null;
      _error = null;
    });
  }

  // ──────────────────────────────────
  // Compress: runs in background isolate
  // ──────────────────────────────────
  Future<void> _handleCompress() async {
    if (_fileBytes == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await compute(_compressPdfIsolate, _fileBytes!);

      if (mounted) {
        setState(() {
          _resultBytes = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  // ──────────────────────────────────
  // Download
  // ──────────────────────────────────
  Future<void> _downloadResult() async {
    if (_resultBytes == null || _file == null) return;
    final fileName = 'kitbase-optimized-${_file!.name}';

    if (kIsWeb) {
      final blob = html.Blob([_resultBytes!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Optimized PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputFile != null) {
        await File(outputFile).writeAsBytes(_resultBytes!);
      }
    }
  }

  Future<void> _changeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      _handleFiles(result.files);
    }
  }

  // ══════════════════════════════════
  // BUILD: Editor panel
  // ══════════════════════════════════
  Widget _buildEditorPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_file == null)
          ToolDropzone(
            onFiles: _handleFiles,
            allowedExtensions: const ['pdf'],
            allowMultiple: false,
            label: 'Upload a PDF to compress',
            sublabel: 'or click to browse from your device',
            supportedText: 'Supported: .PDF (Max 50MB)',
          )
        else ...[
          // File card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1f2937)
                    : const Color(0xFFe5e7eb),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  color: isDark ? Colors.grey[100] : Colors.grey[500],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _file!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[200] : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          ToolActions(
            children: [
              ActionButton(
                onClick: _handleCompress,
                loading: _isProcessing,
                icon: LucideIcons.archive,
                label: 'Optimize PDF',
              ),
              ActionButton(
                onClick: _changeFile,
                icon: LucideIcons.filePlus,
                variant: ActionButtonVariant.secondary,
                label: 'Change File',
              ),
            ],
          ),

          // Note message
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1AF59E0B) : const Color(0xFFFEF3C7),
              border: Border.all(
                color: isDark
                    ? const Color(0x33F59E0B)
                    : const Color(0xFFFDE68A),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFD97706),
                ),
                children: const [
                  TextSpan(
                    text: 'Note: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'This tool performs structural optimization. If your PDF contains large images, the size reduction might be minimal as we prioritize document integrity.',
                  ),
                ],
              ),
            ),
          ),

          // Error state
          if (_error != null) ToolResult(success: false, message: _error!),

          // Result state
          if (_resultBytes != null) ...[
            const SizedBox(height: 24),
            ToolResult(
              success: true,
              message:
                  'Optimized to ${(_resultBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
              pdfBytes: _resultBytes,
              actions: [
                ActionButton(
                  onClick: _downloadResult,
                  icon: LucideIcons.download,
                  fullWidth: true,
                  label: 'Download Optimized PDF',
                  color: Colors.green,
                ),
                ActionButton(
                  onClick: _changeFile,
                  icon: LucideIcons.filePlus,
                  fullWidth: true,
                  label: 'Optimize Another PDF',
                  variant: ActionButtonVariant.secondary,
                ),
              ],
            ),

            // Saved percentage
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  _resultBytes!.length < _file!.size
                      ? 'Saved ${((_file!.size - _resultBytes!.length) / 1024 / 1024).toStringAsFixed(2)} MB (${((1 - _resultBytes!.length / _file!.size) * 100).toStringAsFixed(0)}%)'
                      : 'Already optimized — no further reduction possible.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ══════════════════════════════════
  // BUILD: How It Works sidebar
  // ══════════════════════════════════
  Widget _buildHowItWorks() {
    return const ToolSidebar(
      instructions: [
        'Upload your PDF document.',
        'Click "Optimize PDF" to start.',
        'Wait for the optimization.',
        'Download your reduced file.',
      ],
      specifications: {
        'Processing': 'Device-local',
        'Privacy': 'No files uploaded',
        'Method': 'Structural cleanup',
        'Max file size': '50 MB',
        'Text': 'Preserved & selectable',
      },
    );
  }

  // ══════════════════════════════════
  // BUILD: Main layout
  // ══════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 48.0 : 20.0,
              right: isDesktop ? 48.0 : 20.0,
              top: 40.0,
              bottom: 100.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToolHeader(
                  tool: ToolsRegistry.tools.firstWhere(
                    (t) => t.slug == 'compress',
                  ),
                ),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: _buildEditorPanel(),
                            ),
                          ),
                          const SizedBox(width: 32),
                          SizedBox(width: 320, child: _buildHowItWorks()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEditorPanel(),
                          const SizedBox(height: 32),
                          _buildHowItWorks(),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
