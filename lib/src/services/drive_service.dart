import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Represents a PDF file found in Google Drive.
class DriveFile {
  final String id;
  final String name;
  final int? size; // bytes, may be null for Google-native files

  const DriveFile({required this.id, required this.name, this.size});
}

/// Wraps Google Sign-In and the Drive v3 API.
class DriveService {
  static final DriveService _instance = DriveService._();
  factory DriveService() => _instance;
  DriveService._();

  // driveScope gives read + write access (needed for uploads).
  final _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveScope]);

  GoogleSignInAccount? _account;
  GoogleSignInAccount? get currentAccount => _account;
  bool get isSignedIn => _account != null;

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// Attempts a silent sign-in first; falls back to interactive sign-in.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _account = await _googleSignIn.signInSilently();
    } catch (_) {}
    _account ??= await _googleSignIn.signIn();
    return _account;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  // ── Drive API ────────────────────────────────────────────────────────────────

  Future<drive.DriveApi> _api() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('Not authenticated');
    return drive.DriveApi(client);
  }

  // ── Download ─────────────────────────────────────────────────────────────────

  /// Returns all PDF files visible to the user in Drive.
  /// Paginates automatically.
  Future<List<DriveFile>> listPdfFiles() async {
    final api = await _api();
    final files = <DriveFile>[];
    String? pageToken;

    do {
      final result = await api.files.list(
        q: "mimeType='application/pdf' and trashed=false",
        spaces: 'drive',
        $fields: 'nextPageToken, files(id, name, size)',
        pageToken: pageToken,
        pageSize: 100,
      );
      for (final f in result.files ?? []) {
        if (f.id != null && f.name != null) {
          files.add(
            DriveFile(
              id: f.id!,
              name: f.name!,
              size: f.size != null ? int.tryParse(f.size!) : null,
            ),
          );
        }
      }
      pageToken = result.nextPageToken;
    } while (pageToken != null);

    return files;
  }

  /// Downloads a Drive file to a temporary directory.
  /// Returns the absolute path of the downloaded file.
  Future<String> downloadFile(DriveFile file) async {
    final api = await _api();

    final media =
        await api.files.get(
              file.id,
              downloadOptions: drive.DownloadOptions.fullMedia,
              $fields: 'id',
            )
            as drive.Media;

    final tmp = await getTemporaryDirectory();
    final safeName = file.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final destPath = p.join(
      tmp.path,
      'drive_${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );

    final sink = File(destPath).openWrite();
    await media.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return destPath;
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  /// Uploads [localPath] to the root of the user's Drive.
  /// [fileName] is what the file will be named in Drive.
  /// Returns the Drive file ID of the uploaded file.
  Future<String> uploadFile(String localPath, String fileName) async {
    final api = await _api();
    final file = File(localPath);
    final length = await file.length();
    final mimeType = lookupMimeType(localPath) ?? 'application/pdf';

    final metadata = drive.File()
      ..name = fileName
      ..mimeType = mimeType;

    final media = drive.Media(file.openRead(), length, contentType: mimeType);

    final result = await api.files.create(
      metadata,
      uploadMedia: media,
      $fields: 'id',
    );

    if (result.id == null)
      throw Exception('Upload failed: no file ID returned');
    return result.id!;
  }
}
