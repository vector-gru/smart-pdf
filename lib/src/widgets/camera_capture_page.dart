import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;
  const CameraCapturePage({super.key, required this.camera});

  @override
  State<CameraCapturePage> createState() => _CameraCapturPageState();
}

class _CameraCapturPageState extends State<CameraCapturePage> {
  late CameraController _ctrl;
  bool _ready = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = CameraController(widget.camera, ResolutionPreset.max, enableAudio: false);
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
            if (_ready)
              Center(child: CameraPreview(_ctrl))
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: AppConstants.scannerCloseIconSize),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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
                      border: Border.all(color: Colors.white, width: AppConstants.scannerShutterBorderWidth),
                      color: _capturing ? Colors.grey : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: _capturing
                        ? Padding(
                            padding: const EdgeInsets.all(AppConstants.scannerShutterIconPadding),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: AppConstants.scannerShutterIconStrokeWidth,
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
