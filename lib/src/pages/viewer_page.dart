import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../db/app_db.dart';

class ViewerPage extends StatefulWidget {
  final String pdfPath; // may be relative or absolute
  final String? title;
  const ViewerPage({Key? key, required this.pdfPath, this.title}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  PdfControllerPinch? _pdfController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final absPath = await resolveDocPath(widget.pdfPath);
      if (!mounted) return;
      setState(() {
        _pdfController = PdfControllerPinch(document: PdfDocument.openFile(absPath));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Viewer'),
            if (widget.title != null)
              Text(widget.title!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Could not open PDF:\n$_error', textAlign: TextAlign.center))
          : _pdfController == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(
                  controller: _pdfController!,
                  padding: 4,
                  backgroundDecoration: const BoxDecoration(),
                  scrollDirection: Axis.vertical,
                ),
    );
  }
}
