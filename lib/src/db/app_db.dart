import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' show PdfDocument;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../services/pdf_service.dart';

part 'app_db.g.dart';

/// Resolves a stored relative path back to an absolute path at runtime.
/// If [stored] is already absolute (legacy data), it's returned as-is.
Future<String> resolveDocPath(String stored) async {
  if (p.isAbsolute(stored)) return stored;
  final base = await getApplicationDocumentsDirectory();
  return p.join(base.path, stored);
}

// Tables
class Collections extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get colorHex => text().withDefault(const Constant('#9E8A4F'))();
  TextColumn get iconName => text().withDefault(const Constant('folder'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CollectionDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionId =>
      text().customConstraint('NOT NULL REFERENCES collections(id)')();
  TextColumn get documentId =>
      text().customConstraint('NOT NULL REFERENCES documents(id)')();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {collectionId, documentId},
  ];
}

class Documents extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get pagesCount => integer().withDefault(const Constant(0))();
  TextColumn get thumbnailPath => text().nullable()();
  BoolColumn get isImported => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get documentId =>
      text().customConstraint('NOT NULL REFERENCES documents(id)')();
  IntColumn get pageIndex => integer()();
  TextColumn get imagePath => text()(); // path to saved page image
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(docsDir.path, 'smart_pdf.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Documents, Pages, Collections, CollectionDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(documents, documents.isImported);
      }
      if (from < 3) {
        await m.createTable(collections);
        await m.createTable(collectionDocuments);
      }
    },
  );

  Future<List<Document>> getAllDocuments() {
    return (select(documents)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<List<Document>> getRecentDocuments({int limit = 20}) {
    return (select(documents)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<Document>> getFavouriteDocuments() {
    return (select(documents)
          ..where((d) => d.isFavorite.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> toggleFavourite(String id, bool value) async {
    await (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        isFavorite: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Page>> getPageImages(String documentId) {
    return (select(pages)
          ..where((p) => p.documentId.equals(documentId))
          ..orderBy([(p) => OrderingTerm(expression: p.pageIndex)]))
        .get();
  }

  Future<Document?> getDocumentById(String id) {
    return (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  // ── Collections ────────────────────────────────────────────────────────────

  /// Returns all collections ordered by creation date (newest first).
  Future<List<Collection>> getAllCollections() {
    return (select(collections)..orderBy([
          (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Creates a new collection and returns its generated id.
  Future<String> createCollection({
    required String name,
    String colorHex = '#9E8A4F',
    String iconName = 'folder',
  }) async {
    final id = const Uuid().v4();
    await into(collections).insert(
      CollectionsCompanion.insert(
        id: Value(id),
        name: name,
        colorHex: Value(colorHex),
        iconName: Value(iconName),
      ),
    );
    return id;
  }

  /// Renames an existing collection.
  Future<void> renameCollection(String id, String newName) async {
    await (update(collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(name: Value(newName)),
    );
  }

  /// Updates the colour and icon of a collection.
  Future<void> updateCollectionAppearance(
    String id, {
    required String colorHex,
    required String iconName,
  }) async {
    await (update(collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(
        colorHex: Value(colorHex),
        iconName: Value(iconName),
      ),
    );
  }

  /// Deletes a collection and all its membership rows.
  Future<void> deleteCollection(String id) async {
    await (delete(
      collectionDocuments,
    )..where((cd) => cd.collectionId.equals(id))).go();
    await (delete(collections)..where((c) => c.id.equals(id))).go();
  }

  /// Returns all documents that belong to [collectionId].
  Future<List<Document>> getDocumentsInCollection(String collectionId) async {
    final ids =
        await (select(collectionDocuments)
              ..where((cd) => cd.collectionId.equals(collectionId))
              ..orderBy([
                (cd) => OrderingTerm(
                  expression: cd.addedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    if (ids.isEmpty) return [];
    final docIds = ids.map((r) => r.documentId).toList();
    return (select(documents)..where((d) => d.id.isIn(docIds))).get();
  }

  /// Returns the set of document ids already in [collectionId].
  Future<Set<String>> getDocumentIdsInCollection(String collectionId) async {
    final rows = await (select(
      collectionDocuments,
    )..where((cd) => cd.collectionId.equals(collectionId))).get();
    return rows.map((r) => r.documentId).toSet();
  }

  /// Adds [documentId] to [collectionId] (no-op if already present).
  Future<void> addDocumentToCollection({
    required String collectionId,
    required String documentId,
  }) async {
    await into(collectionDocuments).insertOnConflictUpdate(
      CollectionDocumentsCompanion.insert(
        collectionId: collectionId,
        documentId: documentId,
      ),
    );
  }

  /// Removes [documentId] from [collectionId].
  Future<void> removeDocumentFromCollection({
    required String collectionId,
    required String documentId,
  }) async {
    await (delete(collectionDocuments)..where(
          (cd) =>
              cd.collectionId.equals(collectionId) &
              cd.documentId.equals(documentId),
        ))
        .go();
  }

  /// Returns how many documents are in [collectionId].
  Future<int> getCollectionDocumentCount(String collectionId) async {
    final count = collectionDocuments.id.count();
    final query = selectOnly(collectionDocuments)
      ..addColumns([count])
      ..where(collectionDocuments.collectionId.equals(collectionId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns a map of collectionId → document count for all collections.
  Future<Map<String, int>> getAllCollectionCounts() async {
    final count = collectionDocuments.id.count();
    final query = selectOnly(collectionDocuments)
      ..addColumns([collectionDocuments.collectionId, count])
      ..groupBy([collectionDocuments.collectionId]);
    final rows = await query.get();
    return {
      for (final r in rows)
        r.read(collectionDocuments.collectionId)!: r.read(count) ?? 0,
    };
  }

  /// Returns the most recent thumbnail path among documents in [collectionId],
  /// or null if the collection has no documents with thumbnails.
  Future<String?> getCollectionCoverThumbnail(String collectionId) async {
    final memberRows =
        await (select(collectionDocuments)
              ..where((cd) => cd.collectionId.equals(collectionId))
              ..orderBy([
                (cd) => OrderingTerm(
                  expression: cd.addedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(5))
            .get();
    if (memberRows.isEmpty) return null;
    final docIds = memberRows.map((r) => r.documentId).toList();
    final docs = await (select(
      documents,
    )..where((d) => d.id.isIn(docIds) & d.thumbnailPath.isNotNull())).get();
    if (docs.isEmpty) return null;
    return docs.first.thumbnailPath;
  }

  // ── Documents ──────────────────────────────────────────────────────────────

  Future<void> deleteDocumentById(String id) async {
    // Remove from any collections first
    await (delete(
      collectionDocuments,
    )..where((cd) => cd.documentId.equals(id))).go();
    // delete pages rows
    await (delete(pages)..where((p) => p.documentId.equals(id))).go();
    // delete document row
    await (delete(documents)..where((d) => d.id.equals(id))).go();
  }

  Future<void> renameDocument(String id, String newTitle) async {
    await (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Imports an existing PDF file from [sourcePath] into app storage.
  /// Copies the file, renders the first page as a thumbnail, and inserts a DB row.
  Future<String> importPdfFile(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final docUuid = const Uuid().v4();
    final docFolder = Directory(
      p.join(docsDir.path, 'smart_pdf', 'files', docUuid),
    );
    await docFolder.create(recursive: true);

    final ext = p.extension(sourcePath).toLowerCase().isEmpty
        ? '.pdf'
        : p.extension(sourcePath).toLowerCase();
    final destAbsPath = p.join(docFolder.path, 'document$ext');
    await File(sourcePath).copy(destAbsPath);
    final relativePdfPath = p.relative(destAbsPath, from: docsDir.path);

    int pagesCount = 0;
    String? relativeThumbnailPath;
    try {
      final doc = await PdfDocument.openFile(destAbsPath);
      pagesCount = doc.pagesCount;
      await doc.close();
      final pdfBytes = await File(destAbsPath).readAsBytes();
      await for (final raster in Printing.raster(
        pdfBytes,
        pages: [0],
        dpi: 150,
      )) {
        final thumbsDir = Directory(
          p.join(docsDir.path, 'smart_pdf', 'thumbs'),
        );
        await thumbsDir.create(recursive: true);
        final thumbAbsFile = p.join(thumbsDir.path, '${const Uuid().v4()}.jpg');

        // Composite onto white before JPEG encoding to avoid black thumbnails
        // from PDFs with transparent or CMYK backgrounds.
        final rawImage = await raster.toImage();
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
        canvas.drawImage(rawImage, ui.Offset.zero, ui.Paint());
        final flatImage = await recorder.endRecording().toImage(
          rawImage.width,
          rawImage.height,
        );
        final byteData = await flatImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final pngBytes = byteData!.buffer.asUint8List();

        final compressed = await FlutterImageCompress.compressWithList(
          pngBytes,
          minWidth: 200,
          minHeight: 260,
          quality: 75,
          format: CompressFormat.jpeg,
        );
        await File(thumbAbsFile).writeAsBytes(compressed);
        relativeThumbnailPath = p.relative(thumbAbsFile, from: docsDir.path);
        break;
      }
    } catch (_) {}

    final title = p.basenameWithoutExtension(sourcePath);
    final docId = const Uuid().v4();
    await into(documents).insert(
      DocumentsCompanion.insert(
        id: Value(docId),
        title: title,
        filePath: relativePdfPath,
        pagesCount: Value(pagesCount),
        thumbnailPath: Value(relativeThumbnailPath),
        isImported: const Value(true),
      ),
    );
    return docId;
  }

  /// Creates PDF from images, saves file, writes DB rows and copies page images into a document folder.
  /// [originals] maps each working image path to its true original (unfiltered) temp path,
  /// as tracked by ScannerPage._originals. This ensures the permanent `page_N_orig<ext>`
  /// always reflects the true unfiltered image even after multiple save cycles.
  /// Returns created document id.
  Future<String> createDocumentFromImages(
    String title,
    List<String> imagePaths, {
    Map<String, String> originals = const {},
  }) async {
    return transaction(() async {
      final docsDir = await getApplicationDocumentsDirectory();
      final docUuid = const Uuid().v4();
      final docFolder = Directory(
        p.join(docsDir.path, 'smart_pdf', 'files', docUuid),
      );
      await docFolder.create(recursive: true);

      // Save page images and keep relative paths.
      // For each image we also persist a `page_N_orig<ext>` so that re-editing
      // can always restore the true original regardless of how many times a
      // colour filter has been applied and saved.
      final savedImagePaths = <String>[];
      final relativeImagePaths = <String>[];
      for (var i = 0; i < imagePaths.length; i++) {
        final ext = p.extension(imagePaths[i]);
        final dest = await File(
          imagePaths[i],
        ).copy(p.join(docFolder.path, 'page_${i + 1}$ext'));
        savedImagePaths.add(dest.path);
        relativeImagePaths.add(p.relative(dest.path, from: docsDir.path));

        // Determine the source for the permanent original:
        //   1. Explicitly tracked original from ScannerResult.originals (most reliable)
        //   2. _orig_ sibling in the same temp dir (legacy fallback)
        //   3. The working copy itself (first-time scan — image IS the original)
        final trackedOrig = originals[imagePaths[i]];
        String origSrc;
        if (trackedOrig != null && await File(trackedOrig).exists()) {
          origSrc = trackedOrig;
        } else {
          final sibling = _origSiblingFor(imagePaths[i]);
          origSrc = (sibling != null && await File(sibling).exists())
              ? sibling
              : imagePaths[i];
        }
        await File(
          origSrc,
        ).copy(p.join(docFolder.path, 'page_${i + 1}_orig$ext'));
      }

      final fileName = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final pdfAbsPath = await PdfService.createPdfFromImages(
        savedImagePaths,
        fileName,
      );
      final relativePdfPath = p.relative(pdfAbsPath, from: docsDir.path);

      // Generate thumbnail, store relative path
      String? relativeThumbnailPath;
      if (savedImagePaths.isNotEmpty) {
        final thumbsDir = Directory(
          p.join(docsDir.path, 'smart_pdf', 'thumbs'),
        );
        await thumbsDir.create(recursive: true);
        final thumbAbsFile = p.join(thumbsDir.path, '${const Uuid().v4()}.jpg');
        final result = await FlutterImageCompress.compressAndGetFile(
          savedImagePaths[0],
          thumbAbsFile,
          minWidth: 200,
          minHeight: 260,
          quality: 75,
        );
        if (result != null) {
          relativeThumbnailPath = p.relative(result.path, from: docsDir.path);
        }
      }

      final docId = const Uuid().v4();
      await into(documents).insert(
        DocumentsCompanion.insert(
          id: Value(docId),
          title: title,
          filePath: relativePdfPath,
          pagesCount: Value(savedImagePaths.length),
          thumbnailPath: Value(relativeThumbnailPath),
        ),
      );

      for (var i = 0; i < relativeImagePaths.length; i++) {
        await into(pages).insert(
          PagesCompanion.insert(
            documentId: docId,
            pageIndex: i,
            imagePath: relativeImagePaths[i],
          ),
        );
      }

      return docId;
    });
  }

  /// Returns the path of a `_orig_`-prefixed sibling file that ScannerPage
  /// writes into the temp directory, or null if it doesn't exist on disk.
  /// Used so that createDocumentFromImages can persist the true original even
  /// after a colour filter has already been applied to the working copy.
  static String? _origSiblingFor(String workingPath) {
    final dir = p.dirname(workingPath);
    final base = p.basename(workingPath);
    final candidate = p.join(dir, '_orig_$base');
    if (File(candidate).existsSync()) return candidate;
    return null;
  }
}
