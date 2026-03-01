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
// Isolate-safe split function
// ──────────────────────────────────────────────
Future<List<Map<String, dynamic>>> _splitPdfIsolate(
  Map<String, dynamic> params,
) async {
  final Uint8List inputBytes = params['bytes'];
  final String mode =
      params['mode']; // custom-range, fixed-range, extract-all, extract-select
  final List<Map<String, int>> ranges = List<Map<String, int>>.from(
    (params['ranges'] as List? ?? []).map((e) => Map<String, int>.from(e)),
  );
  final int fixedCount = params['fixedCount'] ?? 1;
  final String extractPages = params['extractPages'] ?? '';
  final bool merge = params['merge'] ?? false;

  final PdfDocument doc = PdfDocument(inputBytes: inputBytes);
  final int totalPages = doc.pages.count;
  final List<Map<String, dynamic>> results = [];

  List<List<int>> pageGroups = [];

  if (mode == 'custom-range') {
    for (final r in ranges) {
      final from = (r['from'] ?? 1).clamp(1, totalPages);
      final to = (r['to'] ?? 1).clamp(from, totalPages);
      final group = <int>[];
      for (int i = from; i <= to; i++) {
        group.add(i - 1); // 0-indexed
      }
      pageGroups.add(group);
    }
  } else if (mode == 'fixed-range') {
    final step = fixedCount.clamp(1, totalPages);
    for (int i = 0; i < totalPages; i += step) {
      final group = <int>[];
      for (int j = i; j < (i + step).clamp(0, totalPages); j++) {
        group.add(j);
      }
      pageGroups.add(group);
    }
  } else if (mode == 'extract-all') {
    for (int i = 0; i < totalPages; i++) {
      pageGroups.add([i]);
    }
  } else if (mode == 'extract-select') {
    // Parse page string like "1, 3-5, 8"
    final selectedPages = <int>{};
    final parts = extractPages
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    for (final part in parts) {
      if (part.contains('-')) {
        final ends = part
            .split('-')
            .map((e) => int.tryParse(e.trim()))
            .toList();
        if (ends.length == 2 && ends[0] != null && ends[1] != null) {
          final s = ends[0]!.clamp(1, totalPages);
          final e = ends[1]!.clamp(1, totalPages);
          for (int i = s; i <= e; i++) {
            selectedPages.add(i - 1);
          }
        }
      } else {
        final p = int.tryParse(part);
        if (p != null && p >= 1 && p <= totalPages) {
          selectedPages.add(p - 1);
        }
      }
    }
    final sorted = selectedPages.toList()..sort();
    if (merge) {
      pageGroups.add(sorted);
    } else {
      for (final p in sorted) {
        pageGroups.add([p]);
      }
    }
  }

  // If merge is on for range modes, combine all groups into one
  if (merge && mode.contains('range')) {
    final allPages = <int>[];
    for (final g in pageGroups) {
      allPages.addAll(g);
    }
    pageGroups = [allPages];
  }

  // Generate output PDFs
  for (int gi = 0; gi < pageGroups.length; gi++) {
    final group = pageGroups[gi];
    final outDoc = PdfDocument();

    for (final pageIdx in group) {
      if (pageIdx >= 0 && pageIdx < totalPages) {
        final srcPage = doc.pages[pageIdx];
        final newPage = outDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          srcPage.createTemplate(),
          const Offset(0, 0),
        );
      }
    }

    final bytes = await outDoc.save();
    results.add({
      'bytes': Uint8List.fromList(bytes),
      'name': 'part-${gi + 1}.pdf',
    });
    outDoc.dispose();
  }

  doc.dispose();
  return results;
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────
class _RangeItem {
  final int id;
  int from;
  int to;
  _RangeItem({required this.id, required this.from, required this.to});
}

// ──────────────────────────────────────────────
// Main Widget
// ──────────────────────────────────────────────
class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen>
    with SingleTickerProviderStateMixin {
  PlatformFile? _file;
  Uint8List? _fileBytes;
  final ScrollController _scrollController = ScrollController();

  // Thumbnails
  List<Uint8List> _pageThumbnails = [];
  bool _loadingThumbnails = false;
  int _totalPages = 0;

  // Processing
  bool _isLoading = false;
  List<Map<String, dynamic>>? _resultFiles;

  // Tab state
  late TabController _tabController;
  String _rangeMode = 'custom'; // custom | fixed
  String _extractMode = 'all'; // all | select

  // Range options
  List<_RangeItem> _ranges = [];
  int _fixedCount = 1;
  bool _mergeRanges = false;

  // Extract options
  String _extractPagesStr = '';
  bool _mergeExtract = false;
  Set<int> _selectedPages = {}; // 1-indexed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
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
      _resultFiles = null;
      _pageThumbnails = [];
      _loadingThumbnails = true;
      _selectedPages = {};
      _extractPagesStr = '';
    });

    // Get page count
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.pages.count;
    doc.dispose();

    _totalPages = count;
    _ranges = [
      _RangeItem(id: DateTime.now().millisecondsSinceEpoch, from: 1, to: count),
    ];

    // Generate thumbnails
    final thumbs = <Uint8List>[];
    try {
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        thumbs.add(await page.toPng());
        if (thumbs.length >= count) break;
      }
    } catch (e) {
      debugPrint('Error generating thumbnails: $e');
    }

    if (mounted) {
      setState(() {
        _pageThumbnails = thumbs;
        _loadingThumbnails = false;
      });
    }
  }

  // ──────────────────────────────────
  // Extract pages string -> Set sync
  // ──────────────────────────────────
  void _syncSelectedFromStr() {
    final newSet = <int>{};
    final parts = _extractPagesStr
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    for (final part in parts) {
      if (part.contains('-')) {
        final ends = part
            .split('-')
            .map((e) => int.tryParse(e.trim()))
            .toList();
        if (ends.length == 2 && ends[0] != null && ends[1] != null) {
          final s = ends[0]!.clamp(1, _totalPages);
          final e = ends[1]!.clamp(1, _totalPages);
          for (int i = s; i <= e; i++) {
            newSet.add(i);
          }
        }
      } else {
        final p = int.tryParse(part);
        if (p != null && p >= 1 && p <= _totalPages) {
          newSet.add(p);
        }
      }
    }
    setState(() => _selectedPages = newSet);
  }

  void _togglePage(int pageNum) {
    final newSet = Set<int>.from(_selectedPages);
    if (newSet.contains(pageNum)) {
      newSet.remove(pageNum);
    } else {
      newSet.add(pageNum);
    }
    final sorted = newSet.toList()..sort();
    setState(() {
      _selectedPages = newSet;
      _extractPagesStr = sorted.join(', ');
    });
  }

  // ──────────────────────────────────
  // Range management
  // ──────────────────────────────────
  void _addRange() {
    final lastTo = _ranges.isNotEmpty ? _ranges.last.to : 0;
    final newFrom = (lastTo + 1).clamp(1, _totalPages);
    setState(() {
      _ranges.add(
        _RangeItem(
          id: DateTime.now().millisecondsSinceEpoch,
          from: newFrom,
          to: _totalPages,
        ),
      );
    });
  }

  void _removeRange(int id) {
    if (_ranges.length <= 1) return;
    setState(() {
      _ranges.removeWhere((r) => r.id == id);
    });
  }

  // ──────────────────────────────────
  // Output info
  // ──────────────────────────────────
  String _calculateOutputInfo() {
    if (_totalPages == 0) return '';
    final tab = _tabController.index; // 0 = range, 1 = extract

    if (tab == 0) {
      if (_rangeMode == 'custom') {
        final count = _mergeRanges ? 1 : _ranges.length;
        return '$count PDF${count != 1 ? 's' : ''} will be created based on your custom ranges.';
      } else {
        final step = _fixedCount.clamp(1, _totalPages);
        final count = (_totalPages / step).ceil();
        return 'The document will be split every $step page(s). $count PDF${count != 1 ? 's' : ''} will be created.';
      }
    } else {
      if (_extractMode == 'all') {
        return 'Every page will be extracted into a separate PDF file. $_totalPages PDFs will be created.';
      } else {
        final count = _selectedPages.length;
        if (count == 0) return 'Please select or enter pages to extract.';
        if (_mergeExtract) {
          return 'Selected pages will be merged into 1 PDF file.';
        }
        return 'Selected pages will be converted into separate PDF files. $count PDF${count != 1 ? 's' : ''} will be created.';
      }
    }
  }

  // ──────────────────────────────────
  // Split handler
  // ──────────────────────────────────
  Future<void> _handleSplit() async {
    if (_fileBytes == null) return;
    setState(() => _isLoading = true);

    try {
      final tab = _tabController.index;
      final String mode;
      if (tab == 0) {
        mode = _rangeMode == 'custom' ? 'custom-range' : 'fixed-range';
      } else {
        mode = _extractMode == 'all' ? 'extract-all' : 'extract-select';
      }

      final results = await compute(_splitPdfIsolate, {
        'bytes': _fileBytes!,
        'mode': mode,
        'ranges': _ranges.map((r) => {'from': r.from, 'to': r.to}).toList(),
        'fixedCount': _fixedCount,
        'extractPages': _extractPagesStr,
        'merge': tab == 0 ? _mergeRanges : _mergeExtract,
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      setState(() {
        _resultFiles = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error splitting PDF: $e'),
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
  Future<void> _downloadFile(Uint8List bytes, String name) async {
    final baseName = _file?.name.replaceAll('.pdf', '') ?? 'split';
    final fileName = '$baseName-$name';

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Split PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputFile != null) {
        await File(outputFile).writeAsBytes(bytes);
      }
    }
  }

  // ══════════════════════════════════
  // BUILD: Page thumbnails grid
  // ══════════════════════════════════
  Widget _buildThumbnailGrid() {
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
    if (_pageThumbnails.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            'No preview available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final tab = _tabController.index;
    final isSelectMode = tab == 1 && _extractMode == 'select';

    // Determine which pages are "selected" for visual highlighting
    Set<int> highlightedPages = {};
    if (tab == 0) {
      if (_rangeMode == 'custom') {
        for (final r in _ranges) {
          for (int i = r.from; i <= r.to; i++) {
            highlightedPages.add(i);
          }
        }
      } else {
        // fixed: all pages highlighted
        for (int i = 1; i <= _totalPages; i++) {
          highlightedPages.add(i);
        }
      }
    } else {
      if (_extractMode == 'all') {
        for (int i = 1; i <= _totalPages; i++) {
          highlightedPages.add(i);
        }
      } else {
        highlightedPages = _selectedPages;
      }
    }

    // Group pages for custom range view
    if (tab == 0 && _rangeMode == 'custom') {
      return _buildRangeGroupedThumbnails(highlightedPages);
    }

    // Group pages for fixed range view
    if (tab == 0 && _rangeMode == 'fixed') {
      return _buildFixedGroupedThumbnails();
    }

    // Flat grid for extract modes
    return _buildFlatThumbnailGrid(highlightedPages, isSelectMode);
  }

  Widget _buildRangeGroupedThumbnails(Set<int> highlighted) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        for (int ri = 0; ri < _ranges.length; ri++) ...[
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: ri < _ranges.length - 1 ? 32 : 0,
              top: 8,
            ),
            child: Column(
              children: [
                // Range label on top
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.pink.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Range ${ri + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.pink[300] : Colors.pink[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Thumbnail container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (
                          int p = _ranges[ri].from;
                          p <= _ranges[ri].to && p <= _totalPages;
                          p++
                        )
                          _buildSingleThumb(p, true, false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFixedGroupedThumbnails() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final step = _fixedCount.clamp(1, _totalPages);
    final groups = <List<int>>[];
    for (int i = 0; i < _totalPages; i += step) {
      final group = <int>[];
      for (int j = i; j < (i + step).clamp(0, _totalPages); j++) {
        group.add(j + 1);
      }
      groups.add(group);
    }

    return Column(
      children: [
        for (int gi = 0; gi < groups.length; gi++) ...[
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: gi < groups.length - 1 ? 32 : 0,
              top: 8,
            ),
            child: Column(
              children: [
                // Block label on top
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Block ${gi + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Thumbnail container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final p in groups[gi])
                          _buildSingleThumb(p, true, false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlatThumbnailGrid(Set<int> highlighted, bool isInteractive) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 1; i <= _totalPages; i++)
          _buildSingleThumb(i, highlighted.contains(i), isInteractive),
      ],
    );
  }

  Widget _buildSingleThumb(int pageNum, bool isSelected, bool isInteractive) {
    final idx = pageNum - 1;
    if (idx < 0 || idx >= _pageThumbnails.length) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isInteractive ? () => _togglePage(pageNum) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? (isDark ? const Color(0xFF1f2937) : Colors.white)
                : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected
                  ? Colors.pink.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      _pageThumbnails[idx],
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (!isSelected && isInteractive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$pageNum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.grey[900])
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════
  // BUILD: Settings sidebar
  // ══════════════════════════════════
  Widget _buildSettingsPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tab = _tabController.index;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF1f2937) : const Color(0xFFe5e7eb),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF030712) : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1f2937)
                      : const Color(0xFFe5e7eb),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.pink,
              indicatorWeight: 3,
              labelColor: Colors.pink,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(
                  icon: Icon(LucideIcons.layoutTemplate, size: 16),
                  text: 'Split by range',
                ),
                Tab(
                  icon: Icon(LucideIcons.layers, size: 16),
                  text: 'Extract pages',
                ),
              ],
            ),
          ),

          // Tab content
          Padding(
            padding: const EdgeInsets.all(20),
            child: tab == 0 ? _buildRangeOptions() : _buildExtractOptions(),
          ),

          // Info bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue[50],
                border: Border.all(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.blue[100]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, size: 18, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calculateOutputInfo(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.blue[300] : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Split button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ActionButton(
              onClick: _handleSplit,
              loading: _isLoading,
              icon: LucideIcons.scissors,
              fullWidth: true,
              label: 'Split PDF',
              color: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────
  // Range tab options
  // ──────────────────────────────────
  Widget _buildRangeOptions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1f2937) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _modeButton(
                  'Custom ranges',
                  _rangeMode == 'custom',
                  () => setState(() => _rangeMode = 'custom'),
                ),
              ),
              Expanded(
                child: _modeButton(
                  'Fixed ranges',
                  _rangeMode == 'fixed',
                  () => setState(() => _rangeMode = 'fixed'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_rangeMode == 'custom') ...[
          // Custom ranges list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _ranges.length,
              itemBuilder: (context, i) {
                final r = _ranges[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          'Range ${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1f2937)
                                : Colors.grey[50],
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[900],
                                  ),
                                  textAlign: TextAlign.center,
                                  controller: TextEditingController(
                                    text: r.from.toString(),
                                  ),
                                  onChanged: (v) {
                                    final val = int.tryParse(v);
                                    if (val != null) {
                                      setState(
                                        () =>
                                            r.from = val.clamp(1, _totalPages),
                                      );
                                    }
                                  },
                                ),
                              ),
                              Text(
                                ' - ',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[900],
                                  ),
                                  textAlign: TextAlign.center,
                                  controller: TextEditingController(
                                    text: r.to.toString(),
                                  ),
                                  onChanged: (v) {
                                    final val = int.tryParse(v);
                                    if (val != null) {
                                      setState(
                                        () => r.to = val.clamp(1, _totalPages),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _ranges.length > 1
                            ? () => _removeRange(r.id)
                            : null,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: _ranges.length > 1
                              ? Colors.red[400]
                              : Colors.grey[400],
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addRange,
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text(
              'Add Range',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.pink,
              backgroundColor: Colors.pink.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckbox(
            'Merge all ranges in one PDF file',
            _mergeRanges,
            (v) => setState(() => _mergeRanges = v),
          ),
        ],

        if (_rangeMode == 'fixed') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1f2937) : Colors.grey[50],
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Split in page ranges of',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    controller: TextEditingController(
                      text: _fixedCount.toString(),
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v);
                      if (val != null && val > 0) {
                        setState(() => _fixedCount = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────
  // Extract tab options
  // ──────────────────────────────────
  Widget _buildExtractOptions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1f2937) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _modeButton(
                  'Extract all pages',
                  _extractMode == 'all',
                  () => setState(() => _extractMode = 'all'),
                ),
              ),
              Expanded(
                child: _modeButton(
                  'Select pages',
                  _extractMode == 'select',
                  () => setState(() => _extractMode = 'select'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_extractMode == 'select') ...[
          Text(
            'Pages to extract',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'e.g. 1, 5-8',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
            controller: TextEditingController(text: _extractPagesStr)
              ..selection = TextSelection.collapsed(
                offset: _extractPagesStr.length,
              ),
            onChanged: (v) {
              _extractPagesStr = v;
              _syncSelectedFromStr();
            },
          ),
          const SizedBox(height: 16),
          _buildCheckbox(
            'Merge extracted pages into one PDF file',
            _mergeExtract,
            (v) => setState(() => _mergeExtract = v),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────
  // Shared widgets
  // ──────────────────────────────────
  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? Colors.grey[700] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? (isDark ? Colors.white : Colors.grey[900])
                  : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1f2937) : Colors.grey[50],
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════
  // BUILD: Main editor panel (left)
  // ══════════════════════════════════
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
                        '${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB • $_totalPages Pages',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _file = null;
                    _fileBytes = null;
                    _resultFiles = null;
                    _pageThumbnails = [];
                    _totalPages = 0;
                  }),
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

          // Thumbnail preview
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildThumbnailGrid(),
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
          message:
              'PDF Split Successfully — ${_resultFiles!.length} file${_resultFiles!.length != 1 ? 's' : ''} created.',
          actions: [
            ActionButton(
              onClick: () {
                for (final f in _resultFiles!) {
                  _downloadFile(f['bytes'] as Uint8List, f['name'] as String);
                }
              },
              icon: LucideIcons.download,
              fullWidth: true,
              label: _resultFiles!.length > 1 ? 'Download All' : 'Download PDF',
              color: Colors.pink,
            ),
            ActionButton(
              onClick: () => setState(() => _resultFiles = null),
              icon: LucideIcons.refreshCw,
              fullWidth: true,
              label: 'Back to Editor',
              variant: ActionButtonVariant.secondary,
            ),
          ],
        ),
        if (_resultFiles!.length > 1) ...[
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1f2937)
                    : const Color(0xFFe5e7eb),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resultFiles!.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1f2937)
                    : const Color(0xFFe5e7eb),
              ),
              itemBuilder: (_, index) {
                final f = _resultFiles![index];
                final bytes = f['bytes'] as Uint8List;
                final name = f['name'] as String;
                final baseName = _file?.name.replaceAll('.pdf', '') ?? 'split';
                return ListTile(
                  leading: const Icon(LucideIcons.fileText, color: Colors.pink),
                  title: Text(
                    '$baseName-$name',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.download),
                    onPressed: () => _downloadFile(bytes, name),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════
  // BUILD: How It Works / Sidebar
  // ══════════════════════════════════
  Widget _buildHowItWorks() {
    return const ToolSidebar(
      instructions: [
        'Upload a PDF document you want to split.',
        'Choose Split by Range or Extract Pages mode.',
        'Configure your ranges, page numbers, or fixed count.',
        'Click Split PDF and download your files.',
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
              bottom: 100.0, // Extra space for bottom nav
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToolHeader(
                  tool: ToolsRegistry.tools.firstWhere(
                    (t) => t.slug == 'split',
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
                        label: 'Upload a PDF to split',
                        sublabel: 'or click to browse from your device',
                        supportedText: 'Supported: .PDF',
                      ),
                    ),
                  )
                else if (_resultFiles != null)
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
                            SizedBox(
                              width: 400,
                              child: Column(
                                children: [
                                  _buildSettingsPanel(),
                                  const SizedBox(height: 24),
                                  _buildHowItWorks(),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSettingsPanel(),
                            const SizedBox(height: 24),
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
