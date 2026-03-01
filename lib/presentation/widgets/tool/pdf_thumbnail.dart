import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PdfThumbnail extends StatefulWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final double borderRadius;

  const PdfThumbnail({
    super.key,
    required this.bytes,
    this.width = 40,
    this.height = 56,
    this.borderRadius = 8,
  });

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(PdfThumbnail oldWidget) {
    if (oldWidget.bytes != widget.bytes) {
      _generateThumbnail();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _generateThumbnail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Rasterize the first page at 72 DPI (sufficient for thumbnails)
      await for (final page in Printing.raster(
        widget.bytes,
        pages: [0],
        dpi: 72,
      )) {
        final imageStream = await page.toPng();
        if (mounted) {
          setState(() {
            _imageData = imageStream;
            _isLoading = false;
          });
        }
        break; // We only need the first page
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 1),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: widget.width * 0.4,
                  height: widget.width * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _imageData != null
            ? Image.memory(_imageData!, fit: BoxFit.cover)
            : Center(
                child: Icon(
                  LucideIcons.fileText,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: widget.width * 0.5,
                ),
              ),
      ),
    );
  }
}
