import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of local document IDs that have been successfully
/// uploaded to Google Drive.
///
/// Usage:
///   final registry = await DriveUploadRegistry.load();
///   registry.markUploaded('doc-id-123');
///   registry.hasUploaded('doc-id-123'); // true
class DriveUploadRegistry {
  static const _key = 'drive_uploaded_doc_ids';

  final SharedPreferences _prefs;
  final Set<String> _ids;

  DriveUploadRegistry._(this._prefs, this._ids);

  /// Loads the registry from shared_preferences.
  static Future<DriveUploadRegistry> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? [];
    return DriveUploadRegistry._(prefs, stored.toSet());
  }

  /// Returns true if [docId] has been uploaded to Drive.
  bool hasUploaded(String docId) => _ids.contains(docId);

  /// Records [docId] as uploaded and persists immediately.
  Future<void> markUploaded(String docId) async {
    if (_ids.add(docId)) {
      await _prefs.setStringList(_key, _ids.toList());
    }
  }

  /// Records all [docIds] as uploaded and persists in a single write.
  Future<void> markAllUploaded(Iterable<String> docIds) async {
    final added = docIds.where(_ids.add).toList();
    if (added.isNotEmpty) {
      await _prefs.setStringList(_key, _ids.toList());
    }
  }

  /// Removes a doc ID (e.g. if the document is deleted locally).
  Future<void> remove(String docId) async {
    if (_ids.remove(docId)) {
      await _prefs.setStringList(_key, _ids.toList());
    }
  }

  /// Clears the entire registry (useful for sign-out / testing).
  Future<void> clear() async {
    _ids.clear();
    await _prefs.remove(_key);
  }
}
