import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ViewerPage extends StatefulWidget {
  final String pdfPath;
  final String? title;
  const ViewerPage({Key? key, required this.pdfPath, this.title}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(document: PdfDocument.openFile(widget.pdfPath));
  }

  @override
  void dispose() {
    _pdfController.dispose();
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
              Text(
                widget.title!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {
            // TODO: implement sharing (share_plus)
          }),
        ],
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        padding: 4,
        backgroundDecoration: const BoxDecoration(),
        scrollDirection: Axis.vertical,
      ),
    );
  }
}