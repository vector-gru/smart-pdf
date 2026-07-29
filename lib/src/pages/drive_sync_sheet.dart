import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';

import '../constants/app_colors.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../services/drive_service.dart';

/// Shows the Google Drive sync bottom-sheet (download + upload tabs).
Future<void> showDriveSyncSheet(
  BuildContext context, {
  required AppDatabase db,
  required DocsNotifier notifier,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DriveSyncSheet(db: db, notifier: notifier),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared state enums
// ─────────────────────────────────────────────────────────────────────────────

enum _LoadState { signingIn, loading, loaded, busy, error }

// ─────────────────────────────────────────────────────────────────────────────
// Root sheet — owns sign-in and TabBar
// ─────────────────────────────────────────────────────────────────────────────

class DriveSyncSheet extends StatefulWidget {
  final AppDatabase db;
  final DocsNotifier notifier;

  const DriveSyncSheet({super.key, required this.db, required this.notifier});

  @override
  State<DriveSyncSheet> createState() => _DriveSyncSheetState();
}

class _DriveSyncSheetState extends State<DriveSyncSheet>
    with SingleTickerProviderStateMixin {
  final _drive = DriveService();
  late final TabController _tabs;

  _LoadState _authState = _LoadState.signingIn;
  String _authError = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _signIn();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _authState = _LoadState.signingIn);
    try {
      final account = await _drive.signIn();
      if (account == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (mounted) setState(() => _authState = _LoadState.loaded);
    } catch (_) {
      if (mounted)
        setState(() {
          _authState = _LoadState.error;
          _authError = AppLocalizations.of(context)!.driveErrorSignIn;
        });
    }
  }

  Future<void> _signOut() async {
    await _drive.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // ── drag handle ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.add_to_drive,
                  color: Color(0xFF4285F4),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.driveSheetTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_authState == _LoadState.loaded && _drive.isSignedIn)
                  TextButton(
                    onPressed: _signOut,
                    child: Text(l10n.driveSignOut),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── tab bar (only when authenticated) ────────────────────────────
          if (_authState == _LoadState.loaded) ...[
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: l10n.driveTabDownload),
                Tab(text: l10n.driveTabUpload),
              ],
            ),
          ],
          const Divider(height: 1),

          // ── body ─────────────────────────────────────────────────────────
          Expanded(child: _buildBody(l10n, scrollController)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ScrollController sc) {
    switch (_authState) {
      case _LoadState.signingIn:
        return _CenteredStatus(text: l10n.driveSigningIn);
      case _LoadState.error:
        return _ErrorView(message: _authError, onRetry: _signIn);
      case _LoadState.loaded:
        return TabBarView(
          controller: _tabs,
          children: [
            _DownloadTab(
              drive: _drive,
              db: widget.db,
              notifier: widget.notifier,
              scrollController: sc,
            ),
            _UploadTab(
              drive: _drive,
              notifier: widget.notifier,
              scrollController: sc,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download tab  (From Drive → import to app)
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadTab extends StatefulWidget {
  final DriveService drive;
  final AppDatabase db;
  final DocsNotifier notifier;
  final ScrollController scrollController;

  const _DownloadTab({
    required this.drive,
    required this.db,
    required this.notifier,
    required this.scrollController,
  });

  @override
  State<_DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<_DownloadTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _LoadState _state = _LoadState.loading;
  String _errorMessage = '';
  List<DriveFile> _files = [];
  final Set<String> _selected = {};
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final files = await widget.drive.listPdfFiles();
      if (!mounted) return;
      setState(() {
        _files = files;
        _selected.clear();
        _state = _LoadState.loaded;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _state = _LoadState.error;
          _errorMessage = AppLocalizations.of(context)!.driveErrorLoad;
        });
    }
  }

  Future<void> _import() async {
    if (_selected.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final toImport = _files.where((f) => _selected.contains(f.id)).toList();
    setState(() {
      _state = _LoadState.busy;
      _current = 0;
      _total = toImport.length;
    });

    int imported = 0;
    bool hadError = false;
    for (final file in toImport) {
      try {
        setState(() => _current = imported + 1);
        final path = await widget.drive.downloadFile(file);
        await widget.db.importPdfFile(path);
        imported++;
      } catch (_) {
        hadError = true;
      }
    }

    await widget.notifier.reload();
    if (!mounted) return;

    Navigator.of(context).pop();
    final messenger = ScaffoldMessenger.of(context);
    if (imported > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.driveImportDone(imported)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (hadError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.driveErrorImport),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleAll() => setState(() {
    if (_selected.length == _files.length) {
      _selected.clear();
    } else {
      _selected.addAll(_files.map((f) => f.id));
    }
  });

  void _toggle(DriveFile f) => setState(
    () =>
        _selected.contains(f.id) ? _selected.remove(f.id) : _selected.add(f.id),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    switch (_state) {
      case _LoadState.loading:
        return _CenteredStatus(text: l10n.driveLoading);
      case _LoadState.busy:
        return _CenteredStatus(
          text: l10n.driveImporting(_current, _total),
          showSpinner: true,
        );
      case _LoadState.error:
        return _ErrorView(message: _errorMessage, onRetry: _load);
      case _LoadState.loaded:
      default:
        if (_files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.driveEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: _files.length,
                itemBuilder: (_, i) {
                  final file = _files[i];
                  return CheckboxListTile(
                    value: _selected.contains(file.id),
                    onChanged: (_) => _toggle(file),
                    title: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: file.size != null
                        ? Text(
                            _fmt(file.size!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    secondary: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFDB4437),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _ActionBar(
              selectedCount: _selected.length,
              totalCount: _files.length,
              onToggleAll: _toggleAll,
              onAction: _selected.isEmpty ? null : _import,
              actionLabel: _selected.isEmpty
                  ? l10n.driveImportButton
                  : '${l10n.driveImportButton} (${_selected.length})',
              actionIcon: Icons.download_rounded,
              l10n: l10n,
            ),
          ],
        );
    }
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload tab  (local docs → Drive)
// ─────────────────────────────────────────────────────────────────────────────

class _UploadTab extends StatefulWidget {
  final DriveService drive;
  final DocsNotifier notifier;
  final ScrollController scrollController;

  const _UploadTab({
    required this.drive,
    required this.notifier,
    required this.scrollController,
  });

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _LoadState _state = _LoadState.loaded;
  final Set<String> _selected = {};
  int _current = 0;
  int _total = 0;

  Future<void> _upload(List<Document> docs) async {
    if (_selected.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final toUpload = docs.where((d) => _selected.contains(d.id)).toList();
    setState(() {
      _state = _LoadState.busy;
      _current = 0;
      _total = toUpload.length;
    });

    int uploaded = 0;
    bool hadError = false;
    for (final doc in toUpload) {
      try {
        setState(() => _current = uploaded + 1);
        final absPath = await resolveDocPath(doc.filePath);
        // Ensure the file name ends with .pdf
        final fileName = doc.title.endsWith('.pdf')
            ? doc.title
            : '${doc.title}.pdf';
        await widget.drive.uploadFile(absPath, fileName);
        uploaded++;
      } catch (_) {
        hadError = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _state = _LoadState.loaded;
      _selected.clear();
    });

    final messenger = ScaffoldMessenger.of(context);
    if (uploaded > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.driveUploadDone(uploaded)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (hadError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.driveErrorUpload),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleAll(List<Document> docs) => setState(() {
    if (_selected.length == docs.length) {
      _selected.clear();
    } else {
      _selected.addAll(docs.map((d) => d.id));
    }
  });

  void _toggle(Document doc) => setState(
    () => _selected.contains(doc.id)
        ? _selected.remove(doc.id)
        : _selected.add(doc.id),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    // All local documents (both scanned and imported)
    final docs = widget.notifier.all;

    if (_state == _LoadState.busy) {
      return _CenteredStatus(
        text: l10n.driveUploading(_current, _total),
        showSpinner: true,
      );
    }

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.filesEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            l10n.driveUploadSheetSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              return CheckboxListTile(
                value: _selected.contains(doc.id),
                onChanged: (_) => _toggle(doc),
                title: Text(
                  doc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  doc.isImported ? 'Imported' : 'Scanned',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                secondary: Icon(
                  doc.isImported
                      ? Icons.picture_as_pdf_outlined
                      : Icons.document_scanner_outlined,
                  color: const Color(0xFF4285F4),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
        const Divider(height: 1),
        _ActionBar(
          selectedCount: _selected.length,
          totalCount: docs.length,
          onToggleAll: () => _toggleAll(docs),
          onAction: _selected.isEmpty ? null : () => _upload(docs),
          actionLabel: _selected.isEmpty
              ? l10n.driveUploadButton
              : '${l10n.driveUploadButton} (${_selected.length})',
          actionIcon: Icons.upload_rounded,
          l10n: l10n,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CenteredStatus extends StatelessWidget {
  final String text;
  final bool showSpinner;

  const _CenteredStatus({required this.text, this.showSpinner = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
          ],
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onToggleAll;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;
  final AppLocalizations l10n;

  const _ActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleAll,
    required this.onAction,
    required this.actionLabel,
    required this.actionIcon,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount == totalCount && totalCount > 0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            TextButton(
              onPressed: onToggleAll,
              child: Text(
                allSelected ? l10n.driveDeselectAll : l10n.driveSelectAll,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
