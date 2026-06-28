import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_constants.dart';
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
  final _shareKey = GlobalKey();

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

  Future<void> _share() async {
    final absPath = await resolveDocPath(widget.pdfPath);
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(0, 0, AppConstants.viewerShareFallbackSize, AppConstants.viewerShareFallbackSize);
    Share.shareXFiles(
      [XFile(absPath, mimeType: 'application/pdf')],
      subject: widget.title,
      sharePositionOrigin: origin,
    );
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
          IconButton(key: _shareKey, icon: const Icon(Icons.share), onPressed: _share),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Could not open PDF:\n$_error', textAlign: TextAlign.center))
          : _pdfController == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(
                  controller: _pdfController!,
                  padding: AppConstants.viewerPdfPadding,
                  backgroundDecoration: const BoxDecoration(),
                  scrollDirection: Axis.vertical,
                ),
    );
  }
}
