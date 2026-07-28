import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';

import '../constants/app_colors.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../services/drive_service.dart';

/// Bottom-sheet that drives the full Google Drive → import flow.
/// Call [showDriveSyncSheet] to display it.
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

// ── Sheet states ─────────────────────────────────────────────────────────────

enum _SheetState { signingIn, loading, loaded, importing, error }

class DriveSyncSheet extends StatefulWidget {
  final AppDatabase db;
  final DocsNotifier notifier;

  const DriveSyncSheet({super.key, required this.db, required this.notifier});

  @override
  State<DriveSyncSheet> createState() => _DriveSyncSheetState();
}

class _DriveSyncSheetState extends State<DriveSyncSheet> {
  final _drive = DriveService();

  _SheetState _state = _SheetState.signingIn;
  String _errorMessage = '';

  List<DriveFile> _files = [];
  final Set<String> _selected = {};

  int _importCurrent = 0;
  int _importTotal = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  // ── Auth + load ─────────────────────────────────────────────────────────────

  Future<void> _start() async {
    setState(() => _state = _SheetState.signingIn);

    try {
      final account = await _drive.signIn();
      if (account == null) {
        // User cancelled the sign-in dialog — just close the sheet.
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _state = _SheetState.error;
          _errorMessage = AppLocalizations.of(context)!.driveErrorSignIn;
        });
      return;
    }

    await _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _state = _SheetState.loading);
    try {
      final files = await _drive.listPdfFiles();
      if (!mounted) return;
      setState(() {
        _files = files;
        _selected.clear();
        _state = _SheetState.loaded;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _state = _SheetState.error;
          _errorMessage = AppLocalizations.of(context)!.driveErrorLoad;
        });
    }
  }

  // ── Import ───────────────────────────────────────────────────────────────────

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final toImport = _files.where((f) => _selected.contains(f.id)).toList();
    setState(() {
      _state = _SheetState.importing;
      _importCurrent = 0;
      _importTotal = toImport.length;
    });

    int imported = 0;
    bool hadError = false;

    for (final file in toImport) {
      try {
        setState(() => _importCurrent = imported + 1);
        final localPath = await _drive.downloadFile(file);
        await widget.db.importPdfFile(localPath);
        imported++;
      } catch (_) {
        hadError = true;
      }
    }

    await widget.notifier.reload();

    if (!mounted) return;

    Navigator.of(context).pop(); // close sheet

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

  // ── Select-all helpers ───────────────────────────────────────────────────────

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _files.length) {
        _selected.clear();
      } else {
        _selected.addAll(_files.map((f) => f.id));
      }
    });
  }

  void _toggleFile(DriveFile file) {
    setState(() {
      if (_selected.contains(file.id)) {
        _selected.remove(file.id);
      } else {
        _selected.add(file.id);
      }
    });
  }

  // ── Sign-out ─────────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    await _drive.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // drag handle
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

          // header
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.driveSheetTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_state == _SheetState.loaded ||
                          _state == _SheetState.importing)
                        Text(
                          l10n.driveSheetSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_state == _SheetState.loaded && _drive.isSignedIn)
                  TextButton(
                    onPressed: _signOut,
                    child: Text(l10n.driveSignOut),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // body
          Expanded(child: _buildBody(l10n, scrollController)),

          // action bar
          if (_state == _SheetState.loaded) ...[
            const Divider(height: 1),
            _ActionBar(
              selectedCount: _selected.length,
              totalCount: _files.length,
              onToggleAll: _toggleSelectAll,
              onImport: _selected.isEmpty ? null : _importSelected,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ScrollController sc) {
    switch (_state) {
      case _SheetState.signingIn:
        return _CenteredStatus(text: l10n.driveSigningIn);
      case _SheetState.loading:
        return _CenteredStatus(text: l10n.driveLoading);
      case _SheetState.importing:
        return _CenteredStatus(
          text: l10n.driveImporting(_importCurrent, _importTotal),
          showSpinner: true,
        );
      case _SheetState.error:
        return _ErrorView(message: _errorMessage, onRetry: _start);
      case _SheetState.loaded:
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
        return ListView.builder(
          controller: sc,
          itemCount: _files.length,
          itemBuilder: (_, i) {
            final file = _files[i];
            final checked = _selected.contains(file.id);
            return CheckboxListTile(
              value: checked,
              onChanged: (_) => _toggleFile(file),
              title: Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: file.size != null
                  ? Text(
                      _formatSize(file.size!),
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
        );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

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
  final VoidCallback? onImport;
  final AppLocalizations l10n;

  const _ActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleAll,
    required this.onImport,
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
              onPressed: onImport,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                selectedCount > 0
                    ? '${l10n.driveImportButton} ($selectedCount)'
                    : l10n.driveImportButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
