import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import 'scanner_page.dart' show ScannerPage, ScannerResult;
import 'viewer_page.dart';

mixin DocActionsMixin<T extends StatefulWidget> on State<T> {
  AppDatabase get db;
  DocsNotifier get notifier;

  Future<void> deleteDoc(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Are you sure you want to delete "${doc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try { final f = File(await resolveDocPath(doc.filePath)); if (await f.exists()) await f.delete(); } catch (_) {}
    await db.deleteDocumentById(doc.id);
    await notifier.reload();
  }

  Future<void> editDoc(Document doc) async {
    final rawPages = await db.getPageImages(doc.id);
    final absImagePaths = await Future.wait(rawPages.map((p) => resolveDocPath(p.imagePath)));
    if (!mounted) return;
    final result = await Navigator.of(context).push<ScannerResult>(
      MaterialPageRoute(builder: (_) => ScannerPage(
        initialImages: absImagePaths,
        initialTitle: doc.title,
      )),
    );
    if (result != null && result.images.isNotEmpty && mounted) {
      await db.deleteDocumentById(doc.id);
      final created = await db.createDocumentFromImages(result.title, result.images);
      await notifier.reload();
      final updated = await db.getDocumentById(created);
      if (updated != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ViewerPage(pdfPath: updated.filePath, title: updated.title), // relative path, resolved in ViewerPage
        ));
      }
    }
  }

  Future<void> toggleFavourite(Document doc) async {
    await db.toggleFavourite(doc.id, !doc.isFavorite);
    await notifier.reload();
  }

  Future<void> renameDoc(Document doc) async {
    final ctr = TextEditingController(text: doc.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(controller: ctr, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctr.text), child: const Text('Save')),
        ],
      ),
    );
    if (newTitle != null && newTitle.trim().isNotEmpty) {
      await db.renameDocument(doc.id, newTitle.trim());
      await notifier.reload();
    }
  }

  Future<void> printDoc(Document doc) async {
    final absPath = await resolveDocPath(doc.filePath);
    await Printing.layoutPdf(onLayout: (_) => File(absPath).readAsBytes());
  }

  void shareDoc(Document doc) async {
    final absPath = await resolveDocPath(doc.filePath);
    Share.shareXFiles([XFile(absPath)]);
  }
}
