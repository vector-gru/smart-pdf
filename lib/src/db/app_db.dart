import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
class Documents extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get pagesCount => integer().withDefault(const Constant(0))();
  TextColumn get thumbnailPath => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get documentId => text().customConstraint('NOT NULL REFERENCES documents(id)')();
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

@DriftDatabase(tables: [Documents, Pages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Document>> getAllDocuments() {
    return (select(documents)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
  }

  Future<List<Document>> getRecentDocuments({int limit = 20}) {
    return (select(documents)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(limit)).get();
  }

  Future<List<Document>> getFavouriteDocuments() {
    return (select(documents)
      ..where((d) => d.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
  }

  Future<void> toggleFavourite(String id, bool value) async {
    await (update(documents)..where((d) => d.id.equals(id)))
        .write(DocumentsCompanion(isFavorite: Value(value), updatedAt: Value(DateTime.now())));
  }

  Future<List<Page>> getPageImages(String documentId) {
    return (select(pages)
      ..where((p) => p.documentId.equals(documentId))
      ..orderBy([(p) => OrderingTerm(expression: p.pageIndex)])).get();
  }

  Future<Document?> getDocumentById(String id) {
    return (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  Future<void> deleteDocumentById(String id) async {
    // delete pages rows
    await (delete(pages)..where((p) => p.documentId.equals(id))).go();
    // delete document row
    await (delete(documents)..where((d) => d.id.equals(id))).go();
  }

  Future<void> renameDocument(String id, String newTitle) async {
    await (update(documents)..where((d) => d.id.equals(id))).write(DocumentsCompanion(title: Value(newTitle), updatedAt: Value(DateTime.now())));
  }

  /// Creates PDF from images, saves file, writes DB rows and copies page images into a document folder.
  /// Returns created document id.
  Future<String> createDocumentFromImages(String title, List<String> imagePaths) async {
    return transaction(() async {
      final docsDir = await getApplicationDocumentsDirectory();
      final docUuid = const Uuid().v4();
      final docFolder = Directory(p.join(docsDir.path, 'smart_pdf', 'files', docUuid));
      await docFolder.create(recursive: true);

      // Save page images and keep relative paths
      final savedImagePaths = <String>[];
      final relativeImagePaths = <String>[];
      for (var i = 0; i < imagePaths.length; i++) {
        final src = File(imagePaths[i]);
        final dest = await src.copy(p.join(docFolder.path, 'page_${i + 1}${p.extension(imagePaths[i])}'));
        savedImagePaths.add(dest.path);
        relativeImagePaths.add(p.relative(dest.path, from: docsDir.path));
      }

      final fileName = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final pdfAbsPath = await PdfService.createPdfFromImages(savedImagePaths, fileName);
      final relativePdfPath = p.relative(pdfAbsPath, from: docsDir.path);

      // Generate thumbnail, store relative path
      String? relativeThumbnailPath;
      if (savedImagePaths.isNotEmpty) {
        final thumbsDir = Directory(p.join(docsDir.path, 'smart_pdf', 'thumbs'));
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
      await into(documents).insert(DocumentsCompanion.insert(
        id: Value(docId),
        title: title,
        filePath: relativePdfPath,
        pagesCount: Value(savedImagePaths.length),
        thumbnailPath: Value(relativeThumbnailPath),
      ));

      for (var i = 0; i < relativeImagePaths.length; i++) {
        await into(pages).insert(PagesCompanion.insert(documentId: docId, pageIndex: i, imagePath: relativeImagePaths[i]));
      }

      return docId;
    });
  }
}