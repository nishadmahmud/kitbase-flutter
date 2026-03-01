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
import 'package:kitbase_flutter/presentation/widgets/tool/tool_file_list.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_actions.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_sidebar.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_result.dart';
import 'package:kitbase_flutter/core/constants/tools_registry.dart';

// Top-level function for background isolate processing
Future<Uint8List> _mergePdfsTask(List<Uint8List> inputs) async {
  final PdfDocument outputDocument = PdfDocument();

  for (final bytes in inputs) {
    if (bytes.isEmpty) continue;

    final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
    for (int i = 0; i < inputDocument.pages.count; i++) {
      final PdfPage page = inputDocument.pages[i];
      final PdfPage newPage = outputDocument.pages.add();
      newPage.graphics.drawPdfTemplate(
        page.createTemplate(),
        const Offset(0, 0),
      );

      // Yield control back to the event loop on web to prevent total browser freeze
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }

  final List<int> mergedBytes = await outputDocument.save();
  outputDocument.dispose();

  return Uint8List.fromList(mergedBytes);
}

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<PlatformFile> _files = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  Uint8List? _mergedBytes;
  String? _mergedFileName;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFiles(List<PlatformFile> newFiles) {
    setState(() {
      _files.addAll(newFiles);
      _mergedBytes = null; // Reset result on new upload
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final PlatformFile target = _files.removeAt(oldIndex);
      _files.insert(newIndex, target);
      _mergedBytes = null; // Reset result if order changes
    });
  }

  void _clearAll() {
    setState(() {
      _files.clear();
    });
  }

  Future<void> _handleMerge() async {
    if (_files.length < 2) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Gather all file bytes asynchronously first (I/O)
      final List<Uint8List> allPdfBytes = [];
      for (final platformFile in _files) {
        if (platformFile.bytes != null) {
          allPdfBytes.add(platformFile.bytes!);
        } else if (platformFile.path != null) {
          final File file = File(platformFile.path!);
          allPdfBytes.add(await file.readAsBytes());
        }
      }

      if (allPdfBytes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 1.5 Give the Flutter Engine time to confidently render the loading spinner UI frame
      // before we potentially block the main thread (critical for Web fallback behavior)
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Run the heavy synchronous PDF packing logic in a background isolate
      final Uint8List mergedBytes = await compute(_mergePdfsTask, allPdfBytes);

      // Scroll back to top to show the ToolResult clearly
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      setState(() {
        _mergedBytes = mergedBytes;
        _mergedFileName =
            'kitbase-merged-${DateTime.now().millisecondsSinceEpoch}.pdf';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error merging PDFs: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout builder to handle responsive switch between 1 and 2 columns
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 48.0 : 24.0,
              right: isDesktop ? 48.0 : 24.0,
              top: 40.0,
              bottom: 100.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToolHeader(
                  tool: ToolsRegistry.tools.firstWhere(
                    (t) => t.slug == 'merge',
                  ),
                ),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMainColumn()),
                      const SizedBox(width: 32),
                      _buildSidebar(),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMainColumn(),
                      const SizedBox(height: 32),
                      _buildSidebar(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadMergedFile() async {
    if (_mergedBytes == null) return;

    final fileName = _mergedFileName ?? 'kitbase-merged.pdf';

    if (kIsWeb) {
      final blob = html.Blob([_mergedBytes!]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merged PDF downloading: $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Merged PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          final File savedFile = File(outputFile);
          await savedFile.writeAsBytes(_mergedBytes!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully merged and saved to $outputFile'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  Widget _buildMainColumn() {
    if (_mergedBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolResult(
            success: true,
            message: "PDF Merged Successfully",
            fileSize:
                "${(_mergedBytes!.length / (1024 * 1024)).toStringAsFixed(2)} MB",
            pdfBytes: _mergedBytes,
            actions: [
              ActionButton(
                onClick: _downloadMergedFile,
                icon: LucideIcons.download,
                fullWidth: true,
                label: "Download Merged PDF",
                color: Colors.pink,
              ),
              ActionButton(
                onClick: () {
                  setState(() {
                    _files.clear();
                    _mergedBytes = null;
                  });
                },
                icon: LucideIcons.refreshCw,
                fullWidth: true,
                label: "Merge More",
                variant: ActionButtonVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _mergedBytes = null;
                _files.clear();
              });
            },
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text("Merge Another"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolDropzone(
          onFiles: _handleFiles,
          allowedExtensions: const ['pdf'],
          allowMultiple: true,
          label: "Drag & drop PDF files here",
          sublabel: "or click to browse from your device",
          supportedText: "Supported: .PDF (Max 50MB each)",
        ),

        ToolFileList(
          files: _files,
          onRemove: _removeFile,
          onClearAll: _clearAll,
          onReorder: _onReorder,
        ),

        ToolActions(
          children: [
            ActionButton(
              label: _files.length > 1
                  ? "Merge ${_files.length} PDFs"
                  : "Merge PDFs",
              icon: LucideIcons.merge,
              loading: _isLoading,
              disabled: _files.length < 2,
              onClick: _handleMerge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return const ToolSidebar(
      instructions: [
        "Upload your PDF files",
        "Drag to reorder if needed",
        "Click Merge and download",
      ],
      specifications: {
        "Max file size": "50 MB each",
        "Accepted format": ".PDF",
        "Processing": "Client-side",
      },
    );
  }
}
