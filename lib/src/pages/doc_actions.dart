import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final isImported = doc.isImported;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isImported ? l10n.docRemoveTitle : l10n.docDeleteTitle),
        content: Text(
          isImported
              ? l10n.docRemoveContent(doc.title)
              : l10n.docDeleteContent(doc.title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.docActionCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isImported ? l10n.docActionRemove : l10n.docActionDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!isImported) {
      try { final f = File(await resolveDocPath(doc.filePath)); if (await f.exists()) await f.delete(); } catch (_) {}
    }
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
          builder: (_) => ViewerPage(pdfPath: updated.filePath, title: updated.title),
        ));
      }
    }
  }

  Future<void> toggleFavourite(Document doc) async {
    final l10n = AppLocalizations.of(context)!;
    await db.toggleFavourite(doc.id, !doc.isFavorite);
    await notifier.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(doc.isFavorite ? l10n.docFavRemoved : l10n.docFavAdded),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> renameDoc(Document doc) async {
    final l10n = AppLocalizations.of(context)!;
    final ctr = TextEditingController(text: doc.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.docRenameTitle),
        content: TextField(controller: ctr, decoration: InputDecoration(labelText: l10n.docRenameLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.docActionCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctr.text), child: Text(l10n.docActionSave)),
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

  void shareDoc(Document doc, Rect shareRect) async {
    final absPath = await resolveDocPath(doc.filePath);
    Share.shareXFiles([XFile(absPath)], sharePositionOrigin: shareRect);
  }
}
