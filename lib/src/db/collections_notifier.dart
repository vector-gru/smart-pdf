import 'package:flutter/foundation.dart';
import 'app_db.dart';

/// Holds the display model for a single collection card on the grid.
class CollectionSummary {
  final Collection collection;
  final int docCount;
  final String? coverThumbnailPath; // absolute path, pre-resolved

  const CollectionSummary({
    required this.collection,
    required this.docCount,
    this.coverThumbnailPath,
  });
}

/// Reactive state for the Collections tab.
/// Call [reload] after any create / rename / delete / membership change.
class CollectionsNotifier extends ChangeNotifier {
  final AppDatabase db;

  List<CollectionSummary> _summaries = [];
  bool _loading = false;

  CollectionsNotifier(this.db);

  List<CollectionSummary> get summaries => _summaries;
  bool get loading => _loading;

  Future<void> reload() async {
    _loading = true;
    notifyListeners();

    final allCollections = await db.getAllCollections();
    final counts = await db.getAllCollectionCounts();

    final summaries = <CollectionSummary>[];
    for (final c in allCollections) {
      final rawThumb = await db.getCollectionCoverThumbnail(c.id);
      String? absThumb;
      if (rawThumb != null && rawThumb.isNotEmpty) {
        absThumb = await resolveDocPath(rawThumb);
      }
      summaries.add(CollectionSummary(
        collection: c,
        docCount: counts[c.id] ?? 0,
        coverThumbnailPath: absThumb,
      ));
    }

    _summaries = summaries;
    _loading = false;
    notifyListeners();
  }
}
