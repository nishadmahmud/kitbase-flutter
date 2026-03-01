import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class CategoryModel {
  final String slug;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tags;

  const CategoryModel({
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.tags,
  });
}

class ToolModel {
  final String name;
  final String slug;
  final String category;
  final String description;
  final IconData icon;
  final String href;
  final bool popular;

  const ToolModel({
    required this.name,
    required this.slug,
    required this.category,
    required this.description,
    required this.icon,
    required this.href,
    this.popular = false,
  });
}

class ToolsRegistry {
  static const List<CategoryModel> categories = [
    CategoryModel(
      slug: "pdf",
      name: "PDF Tools",
      description:
          "Edit, convert, and manage PDF files easily with our suite of powerful document tools.",
      icon: LucideIcons.fileText,
      color: AppColors.catPdf,
      tags: ["Merge", "Split", "Compress", "Convert"],
    ),
    CategoryModel(
      slug: "image",
      name: "Image Tools",
      description:
          "Resize, compress, and convert images with browser-based processing.",
      icon: LucideIcons.image,
      color: AppColors.catImage,
      tags: ["Resize", "Crop", "Filters", "Conversion"],
    ),
    CategoryModel(
      slug: "dev",
      name: "Developer Tools",
      description: "Utilities for formatting, encoding, and data manipulation.",
      icon: LucideIcons.braces,
      color: AppColors.catDev,
      tags: ["JSON", "Markdown", "Base64", "SQL"],
    ),
    CategoryModel(
      slug: "calculator",
      name: "Calculators",
      description:
          "Quick calculation tools for everyday academic and professional needs.",
      icon: LucideIcons.graduationCap,
      color: AppColors.catCalc,
      tags: ["Unit", "Currency", "Percentage", "Math"],
    ),
    CategoryModel(
      slug: "text",
      name: "Text Tools",
      description:
          "Analyze, format, and manipulate text strings with powerful utilities.",
      icon: LucideIcons.type, // Approximation for FileText variation
      color: AppColors.catText,
      tags: ["Count", "Format", "Clean", "Generate"],
    ),
    CategoryModel(
      slug: "design",
      name: "Design Tools",
      description:
          "Create and fine-tune your designs with color, gradient, and CSS utilities.",
      icon: LucideIcons.palette,
      color: AppColors.catDesign,
      tags: ["Color", "CSS", "Gradient", "Contrast"],
    ),
    CategoryModel(
      slug: "security",
      name: "Security Tools",
      description:
          "Generate secure passwords, tokens, and hashes to protect your data.",
      icon: LucideIcons.shield,
      color: AppColors.catSecurity,
      tags: ["Password", "Hash", "Token", "UUID"],
    ),
    CategoryModel(
      slug: "productivity",
      name: "Productivity",
      description:
          "Boost your efficiency with timers, clocks, and focus tools.",
      icon: LucideIcons.timer,
      color: AppColors.catProductivity,
      tags: ["Timer", "Clock", "Focus", "Pomodoro"],
    ),
    CategoryModel(
      slug: "file",
      name: "File Tools",
      description: "Analyze, hash, and extract metadata from your files.",
      icon: LucideIcons.fileSearch,
      color: AppColors.catFile,
      tags: ["Metadata", "Checksum", "Hash", "Security"],
    ),
    CategoryModel(
      slug: "visualization",
      name: "Visualization",
      description: "Generate charts from CSV files or manual data entry.",
      icon: LucideIcons.activity,
      color: AppColors.catVis,
      tags: ["Chart", "Graph", "Plot", "CSV"],
    ),
  ];

  static const List<ToolModel> tools = [
    // PDF Tools
    ToolModel(
      name: "Merge PDF",
      slug: "merge",
      category: "pdf",
      description:
          "Combine multiple PDF files into a single document with ease and speed.",
      icon: LucideIcons.fileText,
      href: "/tools/pdf/merge",
      popular: true,
    ),
    ToolModel(
      name: "Split PDF",
      slug: "split",
      category: "pdf",
      description:
          "Separate one page or a whole set for easy conversion and organization.",
      icon: LucideIcons.scissors,
      href: "/tools/pdf/split",
    ),
    ToolModel(
      name: "Reorder PDF",
      slug: "reorder",
      category: "pdf",
      description:
          "Rearrange pages in your PDF document by dragging them into the right order.",
      icon: LucideIcons.arrowUpDown,
      href: "/tools/pdf/reorder",
    ),
    ToolModel(
      name: "Compress PDF",
      slug: "compress",
      category: "pdf",
      description:
          "Reduce the file size of your PDF without losing original document quality.",
      icon: LucideIcons.archive,
      href: "/tools/pdf/compress",
    ),
    // Image Tools
    ToolModel(
      name: "Resize Image",
      slug: "resize",
      category: "image",
      description:
          "Change image dimensions while maintaining quality and aspect ratio.",
      icon: LucideIcons.image,
      href: "/tools/image/resize",
      popular: true,
    ),
    ToolModel(
      name: "Compress Image",
      slug: "compress",
      category: "image",
      description:
          "Reduce file size of JPG, PNG, and WebP without losing quality.",
      icon: LucideIcons.shrink,
      href: "/tools/image/compress",
      popular: true,
    ),
    ToolModel(
      name: "Convert Image",
      slug: "convert",
      category: "image",
      description:
          "Convert images between JPG, PNG, WebP, and other formats instantly.",
      icon: LucideIcons.refreshCw,
      href: "/tools/image/convert",
    ),
    // Markdown Tools (under dev category)
    ToolModel(
      name: "Markdown Viewer",
      slug: "viewer",
      category: "dev",
      description:
          "Live preview and edit your markdown files with real-time rendering.",
      icon: LucideIcons.eye,
      href: "/tools/markdown/viewer",
      popular: true,
    ),
    ToolModel(
      name: "Markdown to PDF",
      slug: "to-pdf",
      category: "dev",
      description:
          "Export your markdown documents to beautifully formatted PDF files.",
      icon: LucideIcons.fileDown,
      href: "/tools/markdown/to-pdf",
    ),
    // Dev Tools
    ToolModel(
      name: "JSON Formatter",
      slug: "json-formatter",
      category: "dev",
      description:
          "Prettify and validate complex JSON data for better readability.",
      icon: LucideIcons.braces,
      href: "/tools/dev/json-formatter",
      popular: true,
    ),
    ToolModel(
      name: "Base64 Encoder",
      slug: "base64",
      category: "dev",
      description: "Encode and decode Base64 strings quickly in your browser.",
      icon: LucideIcons.binary,
      href: "/tools/dev/base64",
    ),
    // Calculators
    ToolModel(
      name: "GPA Calculator",
      slug: "gpa",
      category: "calculator",
      description:
          "Calculate your GPA instantly with our easy-to-use grade calculator.",
      icon: LucideIcons.graduationCap,
      href: "/tools/calculator/gpa",
    ),
    ToolModel(
      name: "Percentage Calculator",
      slug: "percentage",
      category: "calculator",
      description:
          "Quick percentage calculations for discounts, tips, grades, and more.",
      icon: LucideIcons.percent,
      href: "/tools/calculator/percentage",
    ),
    // URL based tools
    ToolModel(
      name: "QR Code Generator",
      slug: "qr-code",
      category: "dev",
      description:
          "Create customizable QR codes for URLs, Wi-Fi access, and more.",
      icon: LucideIcons.binary,
      href: "/tools/dev/qr-code",
    ),
    ToolModel(
      name: "Text Diff",
      slug: "diff",
      category: "dev",
      description: "Compare two text blocks and highlight the differences.",
      icon: LucideIcons.braces,
      href: "/tools/dev/diff",
    ),
    ToolModel(
      name: "URL Encoder/Decoder",
      slug: "url-encoder",
      category: "dev",
      description:
          "Encode or decode URLs to ensure they are safe for transmission.",
      icon: LucideIcons.link,
      href: "/tools/dev/url-encoder",
    ),
    ToolModel(
      name: "HTML Entity Encoder",
      slug: "html-entities",
      category: "dev",
      description:
          "Convert characters to their corresponding HTML entities and vice versa.",
      icon: LucideIcons.code,
      href: "/tools/dev/html-entities",
    ),
    ToolModel(
      name: "SQL Formatter",
      slug: "sql-formatter",
      category: "dev",
      description:
          "Format and beautify your SQL queries for better readability.",
      icon: LucideIcons.database,
      href: "/tools/dev/sql-formatter",
    ),
    ToolModel(
      name: "JSON <> CSV",
      slug: "json-csv",
      category: "dev",
      description: "Convert data between JSON and CSV formats instantly.",
      icon: LucideIcons.fileSpreadsheet,
      href: "/tools/dev/json-csv",
    ),
    ToolModel(
      name: "Regex Tester",
      slug: "regex-tester",
      category: "dev",
      description:
          "Test and debug JavaScript regular expressions with real-time highlighting.",
      icon: LucideIcons.regex,
      href: "/tools/dev/regex-tester",
    ),
    ToolModel(
      name: "XML Formatter",
      slug: "xml-formatter",
      category: "dev",
      description: "Beautify and validate XML data with proper indentation.",
      icon: LucideIcons.code,
      href: "/tools/dev/xml-formatter",
    ),
    // More PDF Tools
    ToolModel(
      name: "PDF to Image",
      slug: "to-image",
      category: "pdf",
      description: "Convert PDF pages into high-quality JPG or PNG images.",
      icon: LucideIcons.fileDown,
      href: "/tools/pdf/to-image",
    ),
    ToolModel(
      name: "Image to PDF",
      slug: "from-image",
      category: "pdf",
      description: "Convert JPG and PNG images into a single PDF document.",
      icon: LucideIcons.fileText,
      href: "/tools/pdf/from-image",
    ),
    // More Image Tools
    ToolModel(
      name: "Image Filters",
      slug: "filters",
      category: "image",
      description:
          "Enhance photos with brightness, contrast, and artistic filters.",
      icon: LucideIcons.refreshCw,
      href: "/tools/image/filters",
    ),
    ToolModel(
      name: "Image Cropper",
      slug: "crop",
      category: "image",
      description: "Crop images freely or with fixed aspect ratios.",
      icon: LucideIcons.scissors,
      href: "/tools/image/crop",
    ),
    // More Calculators
    ToolModel(
      name: "Unit Converter",
      slug: "unit",
      category: "calculator",
      description: "Convert values between different units of measurement.",
      icon: LucideIcons.arrowUpDown,
      href: "/tools/calculator/unit",
    ),
    // Text Tools
    ToolModel(
      name: "Word Counter",
      slug: "word-counter",
      category: "text",
      description:
          "Count words, characters, sentences, and paragraphs in real-time.",
      icon: LucideIcons.type,
      href: "/tools/text/word-counter",
      popular: true,
    ),
    ToolModel(
      name: "Case Converter",
      slug: "case-converter",
      category: "text",
      description:
          "Convert text to Uppercase, Lowercase, Title Case, CamelCase, and more.",
      icon: LucideIcons.type,
      href: "/tools/text/case-converter",
    ),
    ToolModel(
      name: "Text Cleaner",
      slug: "cleaner",
      category: "text",
      description:
          "Remove extra spaces, duplicate lines, and empty lines from your text.",
      icon: LucideIcons.eraser,
      href: "/tools/text/cleaner",
    ),
    ToolModel(
      name: "String Transform",
      slug: "transform",
      category: "text",
      description:
          "Reverse text, shuffle characters, or repeat strings instantly.",
      icon: LucideIcons.refreshCw,
      href: "/tools/text/transform",
    ),
    ToolModel(
      name: "Lorem Ipsum",
      slug: "lorem",
      category: "text",
      description:
          "Generate placeholder text for your design and development projects.",
      icon: LucideIcons.fileText,
      href: "/tools/text/lorem",
    ),
    // Design Tools
    ToolModel(
      name: "Color Converter",
      slug: "color-converter",
      category: "design",
      description: "Convert colors between HEX, RGB, HSL, and CMYK formats.",
      icon: LucideIcons.palette,
      href: "/tools/design/color-converter",
    ),
    ToolModel(
      name: "Gradient Generator",
      slug: "gradient-generator",
      category: "design",
      description:
          "Create beautiful CSS gradients and copy the code instantly.",
      icon: LucideIcons.palette,
      href: "/tools/design/gradient-generator",
    ),
    // Security Tools
    ToolModel(
      name: "Password Generator",
      slug: "password-generator",
      category: "security",
      description:
          "Generate strong, secure passwords with custom requirements.",
      icon: LucideIcons.shield,
      href: "/tools/security/password-generator",
      popular: true,
    ),
    ToolModel(
      name: "Hash Generator",
      slug: "hash-generator",
      category: "security",
      description:
          "Calculate MD5, SHA-1, SHA-256, and SHA-512 hashes for any text.",
      icon: LucideIcons.shield,
      href: "/tools/security/hash-generator",
    ),
    ToolModel(
      name: "Token Generator",
      slug: "token-generator",
      category: "security",
      description: "Generate random UUIDs and secure authentication tokens.",
      icon: LucideIcons.shield,
      href: "/tools/security/token-generator",
    ),
    // Productivity Tools
    ToolModel(
      name: "Pomodoro Timer",
      slug: "pomodoro",
      category: "productivity",
      description: "Boost focus with customizable work and break intervals.",
      icon: LucideIcons.timer,
      href: "/tools/productivity/pomodoro",
      popular: true,
    ),
    ToolModel(
      name: "Stopwatch",
      slug: "stopwatch",
      category: "productivity",
      description: "Precise digital stopwatch with lap tracking.",
      icon: LucideIcons.clock,
      href: "/tools/productivity/stopwatch",
    ),
    ToolModel(
      name: "World Clock",
      slug: "world-clock",
      category: "productivity",
      description: "Track time across multiple timezones instantly.",
      icon: LucideIcons.globe,
      href: "/tools/productivity/world-clock",
    ),
    // Financial Calculators
    ToolModel(
      name: "Loan Calculator",
      slug: "loan",
      category: "calculator",
      description: "Calculate monthly payments and total interest for loans.",
      icon: LucideIcons.dollarSign,
      href: "/tools/calculator/loan",
    ),
    ToolModel(
      name: "Interest Calculator",
      slug: "interest",
      category: "calculator",
      description: "Compute simple and compound interest over time.",
      icon: LucideIcons.calculator,
      href: "/tools/calculator/interest",
    ),
    // PDF Security
    ToolModel(
      name: "Protect PDF",
      slug: "protect",
      category: "pdf",
      description: "Encrypt your PDF with a password to restrict access.",
      icon: LucideIcons.lock,
      href: "/tools/pdf/protect",
    ),
    ToolModel(
      name: "Unlock PDF",
      slug: "unlock",
      category: "pdf",
      description: "Remove passwords from PDF files instantly.",
      icon: LucideIcons.lockOpen,
      href: "/tools/pdf/unlock",
    ),
    ToolModel(
      name: "Watermark PDF",
      slug: "watermark",
      category: "pdf",
      description: "Stamp text or images over your PDF pages.",
      icon: LucideIcons.stamp,
      href: "/tools/pdf/watermark",
    ),
    ToolModel(
      name: "Sign PDF",
      slug: "sign",
      category: "pdf",
      description: "Add your signature to PDF documents visually.",
      icon: LucideIcons.penTool,
      href: "/tools/pdf/sign",
    ),
    // File Utilities
    ToolModel(
      name: "Checksum Verifier",
      slug: "checksum",
      category: "file",
      description: "Generate and compare MD5, SHA-1, and SHA-256 file hashes.",
      icon: LucideIcons.binary,
      href: "/tools/file/checksum",
    ),
    ToolModel(
      name: "Metadata Viewer",
      slug: "metadata",
      category: "file",
      description: "View hidden file details, EXIF data, and PDF properties.",
      icon: LucideIcons.info,
      href: "/tools/file/metadata",
    ),
    // Visualization Tools
    ToolModel(
      name: "Chart Generator",
      slug: "chart-generator",
      category: "visualization",
      description:
          "Create Bar, Line, Area, and Pie charts from CSV or manual data.",
      icon: LucideIcons.activity,
      href: "/tools/visualization/chart-generator",
      popular: true,
    ),
    ToolModel(
      name: "EDA Workspace",
      slug: "eda",
      category: "visualization",
      description:
          "Perform exploratory data analysis with descriptive statistics and advanced plots.",
      icon: LucideIcons.trendingUp,
      href: "/tools/visualization/eda",
      popular: true,
    ),
  ];

  static List<ToolModel> getToolsByCategory(String categorySlug) {
    return tools.where((tool) => tool.category == categorySlug).toList();
  }

  static CategoryModel? getCategoryBySlug(String slug) {
    try {
      return categories.firstWhere((cat) => cat.slug == slug);
    } catch (_) {
      return null;
    }
  }

  static List<ToolModel> getPopularTools() {
    return tools.where((tool) => tool.popular).toList();
  }

  static List<ToolModel> searchTools(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return tools.where((tool) {
      return tool.name.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q) ||
          tool.category.toLowerCase().contains(q);
    }).toList();
  }
}
