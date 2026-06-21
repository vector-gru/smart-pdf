import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Minimal PDF service: build a PDF from list of image file paths and save it.
/// Returns the saved PDF absolute path.
class PdfService {
  static Future<String> createPdfFromImages(List<String> imagePaths, String fileName) async {
    final pdf = pw.Document();
    for (final imgPath in imagePaths) {
      final bytes = await File(imgPath).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'smart_pdf', 'files'));
    await dir.create(recursive: true);
    final outPath = p.join(dir.path, '$fileName.pdf');
    final outFile = File(outPath);
    await outFile.writeAsBytes(await pdf.save());
    return outFile.path;
  }
}