import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:kitbase_flutter/presentation/widgets/tool/tool_header.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_dropzone.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_actions.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_sidebar.dart';
import 'package:kitbase_flutter/presentation/widgets/tool/tool_result.dart';
import 'package:kitbase_flutter/core/constants/tools_registry.dart';

// ──────────────────────────────────────────────
// Isolate: Reorder PDF pages
// ──────────────────────────────────────────────
Future<Uint8List> _reorderPdfIsolate(Map<String, dynamic> params) async {
  final Uint8List inputBytes = params['bytes'];
  final List<int> order = List<int>.from(
    params['order'],
  ); // 0-indexed original page indices

  final PdfDocument srcDoc = PdfDocument(inputBytes: inputBytes);
  final PdfDocument outDoc = PdfDocument();

  for (final pageIdx in order) {
    if (pageIdx >= 0 && pageIdx < srcDoc.pages.count) {
      final srcPage = srcDoc.pages[pageIdx];
      final newPage = outDoc.pages.add();
      newPage.graphics.drawPdfTemplate(
        srcPage.createTemplate(),
        const Offset(0, 0),
      );
    }
  }

  final bytes = await outDoc.save();
  outDoc.dispose();
  srcDoc.dispose();
  return Uint8List.fromList(bytes);
}

// ──────────────────────────────────────────────
// Page model
// ──────────────────────────────────────────────
class _PageItem {
  final int originalIndex; // 0-indexed
  final int id; // unique id for keying
  Uint8List? thumbnail;

  _PageItem({required this.originalIndex, required this.id, this.thumbnail});
}

// ──────────────────────────────────────────────
// Main Widget
// ──────────────────────────────────────────────
class ReorderPdfScreen extends StatefulWidget {
  const ReorderPdfScreen({super.key});

  @override
  State<ReorderPdfScreen> createState() => _ReorderPdfScreenState();
}

class _ReorderPdfScreenState extends State<ReorderPdfScreen> {
  PlatformFile? _file;
  Uint8List? _fileBytes;
  final ScrollController _scrollController = ScrollController();

  List<_PageItem> _pages = [];
  bool _loadingThumbnails = false;
  bool _isProcessing = false;
  Uint8List? _resultBytes;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      _pages = [];
      _loadingThumbnails = true;
    });

    // Get page count
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.pages.count;
    doc.dispose();

    // Create page items
    final pages = List.generate(
      count,
      (i) => _PageItem(originalIndex: i, id: i + 1),
    );

    // Generate thumbnails
    try {
      int idx = 0;
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        if (idx < pages.length) {
          pages[idx].thumbnail = await page.toPng();
        }
        idx++;
        if (idx >= count) break;
      }
    } catch (e) {
      debugPrint('Error generating thumbnails: $e');
    }

    if (mounted) {
      setState(() {
        _pages = pages;
        _loadingThumbnails = false;
      });
    }
  }

  // ──────────────────────────────────
  // Page operations
  // ──────────────────────────────────
  void _removePage(int id) {
    if (_pages.length <= 1) return;
    setState(() {
      _pages.removeWhere((p) => p.id == id);
    });
  }

  void _movePage(int id, String direction) {
    final index = _pages.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (direction == 'up' && index > 0) {
      setState(() {
        final item = _pages.removeAt(index);
        _pages.insert(index - 1, item);
      });
    } else if (direction == 'down' && index < _pages.length - 1) {
      setState(() {
        final item = _pages.removeAt(index);
        _pages.insert(index + 1, item);
      });
    }
  }

  // ──────────────────────────────────
  // Reorder & Save
  // ──────────────────────────────────
  Future<void> _handleReorder() async {
    if (_fileBytes == null || _pages.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final order = _pages.map((p) => p.originalIndex).toList();

      final result = await compute(_reorderPdfIsolate, {
        'bytes': _fileBytes!,
        'order': order,
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      setState(() {
        _resultBytes = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────
  // Download
  // ──────────────────────────────────
  Future<void> _downloadResult() async {
    if (_resultBytes == null) return;
    final fileName = 'kitbase-reordered-${_file?.name ?? 'document.pdf'}';

    if (kIsWeb) {
      final blob = html.Blob([_resultBytes!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Reordered PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputFile != null) {
        await File(outputFile).writeAsBytes(_resultBytes!);
      }
    }
  }

  void _reset() {
    setState(() {
      _file = null;
      _fileBytes = null;
      _resultBytes = null;
      _pages = [];
    });
  }

  // ══════════════════════════════════
  // BUILD: Single page card
  // ══════════════════════════════════
  Widget _buildPageCard(_PageItem page, int currentIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: ValueKey(page.id),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Thumbnail
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF030712) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151)
                          : Colors.grey[200]!,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        // Image
                        if (page.thumbnail != null)
                          Positioned.fill(
                            child: Image.memory(
                              page.thumbnail!,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const Center(
                            child: Text(
                              'Preview unavailable',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                        // Original page number badge
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${page.originalIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Grip icon
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              LucideIcons.gripVertical,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Move buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _moveButton(
                      icon: LucideIcons.arrowUp,
                      enabled: currentIndex > 0,
                      onTap: () => _movePage(page.id, 'up'),
                    ),
                    const SizedBox(width: 4),
                    _moveButton(
                      icon: LucideIcons.arrowDown,
                      enabled: currentIndex < _pages.length - 1,
                      onTap: () => _movePage(page.id, 'down'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove button
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: _pages.length > 1 ? () => _removePage(page.id) : null,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _pages.length > 1 ? Colors.red[500] : Colors.grey[400],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.x, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? (isDark ? Colors.grey[200] : Colors.grey[700])
              : (isDark ? Colors.grey[600] : Colors.grey[300]),
        ),
      ),
    );
  }

  // ══════════════════════════════════
  // BUILD: Page grid with live reorder
  // ══════════════════════════════════
  int? _draggedIndex;
  List<_PageItem>? _preOrderSnapshot;

  Widget _buildPageGrid() {
    if (_loadingThumbnails) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Generating page previews...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_pages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            'No pages available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600
            ? 4
            : constraints.maxWidth > 400
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            final page = _pages[index];
            final isDragging = _draggedIndex == index;

            return DragTarget<int>(
              onWillAcceptWithDetails: (details) {
                final fromIndex = details.data;
                if (fromIndex == index) return true;
                // Live reorder: move item as user hovers
                setState(() {
                  final item = _pages.removeAt(fromIndex);
                  _pages.insert(index, item);
                  _draggedIndex = index;
                });
                return true;
              },
              onAcceptWithDetails: (_) {
                // Drop confirmed — keep new order, clear drag state
                setState(() {
                  _draggedIndex = null;
                  _preOrderSnapshot = null;
                });
              },
              onLeave: (_) {},
              builder: (context, candidateData, rejectedData) {
                return Draggable<int>(
                  data: index,
                  onDragStarted: () {
                    setState(() {
                      _draggedIndex = index;
                      // Save snapshot to revert on cancel
                      _preOrderSnapshot = _pages
                          .map(
                            (p) => _PageItem(
                              originalIndex: p.originalIndex,
                              id: p.id,
                              thumbnail: p.thumbnail,
                            ),
                          )
                          .toList();
                    });
                  },
                  onDragEnd: (_) {
                    // If drag ended without acceptance (cancelled)
                    if (_draggedIndex != null && _preOrderSnapshot != null) {
                      setState(() {
                        _pages = _preOrderSnapshot!;
                        _draggedIndex = null;
                        _preOrderSnapshot = null;
                      });
                    }
                  },
                  onDragCompleted: () {
                    // Successfully dropped — keep current order
                    setState(() {
                      _draggedIndex = null;
                      _preOrderSnapshot = null;
                    });
                  },
                  feedback: Material(
                    color: Colors.transparent,
                    elevation: 12,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 150,
                      child: Opacity(
                        opacity: 0.9,
                        child: _buildPageCard(page, index),
                      ),
                    ),
                  ),
                  childWhenDragging: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 0.3,
                    child: _buildPageCard(page, index),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: isDragging
                        ? (Matrix4.identity()..scale(0.95))
                        : Matrix4.identity(),
                    transformAlignment: Alignment.center,
                    child: _buildPageCard(page, index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEditorPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFf9fafb),
        border: Border.all(
          color: isDark ? const Color(0xFF1f2937) : const Color(0xFFe5e7eb),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // File header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF030712) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1f2937)
                      : const Color(0xFFe5e7eb),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x4D881337)
                        : const Color(0xFFfce7f3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    color: Color(0xFFe11d48),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _file!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB • ${_pages.length} Pages',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.grey[200]
                        : Colors.grey[800],
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Change File'),
                ),
              ],
            ),
          ),

          // Page grid
          Padding(padding: const EdgeInsets.all(20), child: _buildPageGrid()),

          // Actions
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: ActionButton(
                    onClick: _handleReorder,
                    loading: _isProcessing,
                    icon: LucideIcons.arrowUpDown,
                    fullWidth: true,
                    label: 'Reorder & Download',
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════
  // BUILD: Result panel
  // ══════════════════════════════════
  Widget _buildResultPanel() {
    return Column(
      children: [
        ToolResult(
          success: true,
          message: 'PDF Reordered Successfully',
          pdfBytes: _resultBytes,
          actions: [
            ActionButton(
              onClick: _downloadResult,
              icon: LucideIcons.download,
              fullWidth: true,
              label: 'Download Reordered PDF',
              color: Colors.green,
            ),
            ActionButton(
              onClick: () => setState(() => _resultBytes = null),
              icon: LucideIcons.refreshCw,
              fullWidth: true,
              label: 'Back to Editor',
              variant: ActionButtonVariant.secondary,
            ),
            ActionButton(
              onClick: _reset,
              icon: LucideIcons.filePlus,
              fullWidth: true,
              label: 'Reorder Another PDF',
              variant: ActionButtonVariant.secondary,
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════
  // BUILD: How It Works sidebar
  // ══════════════════════════════════
  Widget _buildHowItWorks() {
    return const ToolSidebar(
      instructions: [
        'Upload a PDF document.',
        'Drag and drop pages to rearrange their order.',
        'Use arrow buttons or remove unwanted pages.',
        'Click "Reorder & Download" to save the result.',
      ],
      specifications: {
        'Processing': 'Everything runs on your device',
        'Privacy': 'No files uploaded to any server',
        'Quality': 'Original PDF quality preserved',
        'Security': 'Files stay private & secure',
      },
    );
  }

  // ══════════════════════════════════
  // BUILD: Main
  // ══════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return SingleChildScrollView(
          controller: _scrollController,
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
                    (t) => t.slug == 'reorder',
                  ),
                ),
                if (_file == null)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ToolDropzone(
                        onFiles: _handleFiles,
                        allowedExtensions: const ['pdf'],
                        allowMultiple: false,
                        label: 'Upload a PDF to reorder',
                        sublabel: 'or click to browse from your device',
                        supportedText: 'Supported: .PDF (Max 50MB)',
                      ),
                    ),
                  )
                else if (_resultBytes != null)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildResultPanel(),
                    ),
                  )
                else
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildEditorPanel()),
                            const SizedBox(width: 24),
                            SizedBox(width: 320, child: _buildHowItWorks()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildEditorPanel(),
                            const SizedBox(height: 24),
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
