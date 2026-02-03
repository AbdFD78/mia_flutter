import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String url;
  final String? title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title ?? 'Document PDF',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SfPdfViewer.network(url),
    );
  }
}

