import 'package:flutter/foundation.dart';
import 'app_db.dart';

/// Single source of truth for documents. All pages listen to this.
class DocsNotifier extends ChangeNotifier {
  final AppDatabase db;
  List<Document> _all = [];

  DocsNotifier(this.db);

  List<Document> get all => _all;
  List<Document> get recent => _all.take(20).toList();
  List<Document> get favourites => _all.where((d) => d.isFavorite).toList();

  Future<void> reload() async {
    _all = await db.getAllDocuments();
    notifyListeners();
  }
}
