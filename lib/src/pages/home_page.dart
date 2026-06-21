// Home page - list of saved PDFs
import 'dart:io';
import 'package:flutter/material.dart';
import '../db/app_db.dart';
import 'scanner_page.dart';
import 'viewer_page.dart';

class HomePage extends StatefulWidget {
  final AppDatabase db;
  const HomePage({Key? key, required this.db}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Document>>? _docsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  void _loadDocs() {
    _docsFuture = widget.db.getAllDocuments();
    setState(() {});
  }

  Future<void> _deleteDoc(Document doc) async {
    // delete actual file if exists, then delete DB entries
    try {
      final f = File(doc.filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await widget.db.deleteDocumentById(doc.id);
    _loadDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('smart-pdf'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: implement search
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(child: Text('Premium', style: TextStyle(fontWeight: FontWeight.w600))),
          )
        ],
      ),
      body: FutureBuilder<List<Document>>(
        future: _docsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No documents yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start a scan'),
                    onPressed: _openScanner,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              return ListTile(
                leading: Container(
                  width: 52,
                  height: 68,
                  color: Colors.grey[200],
                  child: d.pagesCount > 0
                      ? Image.file(File(d.thumbnailPath ?? ''), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf))
                      : const Icon(Icons.picture_as_pdf),
                ),
                title: Text(d.title),
                subtitle: Text('${d.pagesCount} page(s)'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: d.filePath)));
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await _deleteDoc(d);
                    } else if (v == 'rename') {
                      final newTitle = await _askRename(context, d.title);
                      if (newTitle != null && newTitle.trim().isNotEmpty) {
                        await widget.db.renameDocument(d.id, newTitle.trim());
                        _loadDocs();
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  void _openScanner() async {
    final result = await Navigator.of(context).push<List<String>>(MaterialPageRoute(builder: (_) => ScannerPage()));
    if (result != null && result.isNotEmpty) {
      // Ask for a filename, create PDF, and save to DB
      final title = await _askRename(context, 'Document_${DateTime.now().millisecondsSinceEpoch}');
      if (title == null) return;
      final created = await widget.db.createDocumentFromImages(title.trim(), result);
      // created returns document id
      _loadDocs();
      // show the created document
      final doc = await widget.db.getDocumentById(created);
      if (doc != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: doc.filePath)));
      }
    }
  }

  Future<String?> _askRename(BuildContext context, String current) {
    final ctr = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document name'),
        content: TextField(controller: ctr, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctr.text), child: const Text('Save')),
        ],
      ),
    );
  }
}