import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Result from a single-shot capture.
typedef CameraCaptureResult = String;

/// A full-screen camera viewfinder that captures one photo and pops its path.
///
/// [instructionLabel] — optional banner overlay (e.g. "Capture front side").
class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;
  final String? instructionLabel;

  const CameraCapturePage({
    super.key,
    required this.camera,
    this.instructionLabel,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _ctrl;
  bool _ready = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _ctrl.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _ctrl.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Live viewfinder
            if (_ready)
              Center(child: CameraPreview(_ctrl))
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: AppConstants.scannerCloseIconSize,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Instruction banner
            if (widget.instructionLabel != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.instructionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Shutter button
            Positioned(
              bottom: AppConstants.scannerShutterBottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: AppConstants.scannerShutterSize,
                    height: AppConstants.scannerShutterSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: AppConstants.scannerShutterBorderWidth,
                      ),
                      color: _capturing
                          ? Colors.grey
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: _capturing
                        ? Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.scannerShutterIconPadding,
                            ),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth:
                                  AppConstants.scannerShutterIconStrokeWidth,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ID Card dual-shot camera page
// ─────────────────────────────────────────────────────────────────────────────

/// Result returned from [IdCardCameraPage]: the paths of the front and back
/// photos captured in sequence.
class IdCardCameraResult {
  final String frontPath;
  final String backPath;
  IdCardCameraResult({required this.frontPath, required this.backPath});
}

/// A single full-screen camera session that captures two photos in sequence
/// (front → back) while keeping the live preview active the whole time.
///
/// Returns an [IdCardCameraResult] or null if the user cancels.
class IdCardCameraPage extends StatefulWidget {
  final CameraDescription camera;
  final String frontLabel;
  final String backLabel;

  const IdCardCameraPage({
    super.key,
    required this.camera,
    required this.frontLabel,
    required this.backLabel,
  });

  @override
  State<IdCardCameraPage> createState() => _IdCardCameraPageState();
}

class _IdCardCameraPageState extends State<IdCardCameraPage> {
  late CameraController _ctrl;
  bool _ready = false;
  bool _capturing = false;

  /// null = waiting for front, non-null = waiting for back
  String? _frontPath;

  @override
  void initState() {
    super.initState();
    _ctrl = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _ctrl.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _waitingForFront => _frontPath == null;

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _ctrl.takePicture();
      if (!mounted) return;

      if (_waitingForFront) {
        // First shot done — show a brief flash then switch to back-side mode
        setState(() {
          _frontPath = file.path;
          _capturing = false;
        });
      } else {
        // Second shot done — pop with both paths
        Navigator.pop(
          context,
          IdCardCameraResult(frontPath: _frontPath!, backPath: file.path),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = _waitingForFront
        ? widget.frontLabel
        : widget.backLabel;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Live viewfinder — stays alive for both shots
            if (_ready)
              Center(child: CameraPreview(_ctrl))
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Close / back button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  _waitingForFront ? Icons.close : Icons.arrow_back,
                  color: Colors.white,
                  size: AppConstants.scannerCloseIconSize,
                ),
                onPressed: () {
                  if (_waitingForFront) {
                    Navigator.pop(context); // cancel
                  } else {
                    // Go back to re-capture the front
                    setState(() => _frontPath = null);
                  }
                },
              ),
            ),

            // Step indicator (1 of 2 / 2 of 2)
            Positioned(
              top: 8,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _waitingForFront ? '1 / 2' : '2 / 2',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),

            // Instruction banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(currentLabel),
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Thumbnail of captured front (shown while waiting for back)
            if (!_waitingForFront)
              Positioned(
                bottom:
                    AppConstants.scannerShutterBottom +
                    AppConstants.scannerShutterSize +
                    16,
                left: 16,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(File(_frontPath!), fit: BoxFit.cover),
                  ),
                ),
              ),

            // Shutter button
            Positioned(
              bottom: AppConstants.scannerShutterBottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: AppConstants.scannerShutterSize,
                    height: AppConstants.scannerShutterSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: AppConstants.scannerShutterBorderWidth,
                      ),
                      color: _capturing
                          ? Colors.grey
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: _capturing
                        ? Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.scannerShutterIconPadding,
                            ),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth:
                                  AppConstants.scannerShutterIconStrokeWidth,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
