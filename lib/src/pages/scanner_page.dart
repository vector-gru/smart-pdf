import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Simple scanner page:
/// - pick images from camera or gallery
/// - optional crop per-image
/// - returns saved image file paths (List<String>) when user taps SAVE
class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final List<String> _images = [];
  final _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x == null) return;
    await _processPicked(x);
  }

  Future<void> _pickFromGallery() async {
    final list = await _picker.pickMultiImage(imageQuality: 90);
    if (list == null || list.isEmpty) return;
    for (final x in list) {
      await _processPicked(x);
    }
  }

  Future<void> _processPicked(XFile picked) async {
    // Optional: open cropper
    CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop', lockAspectRatio: false),
          IOSUiSettings(title: 'Crop'),
        ],
      );
    } catch (_) {
      // Cropper failed/cancelled — use original image
    }

    final toCopy = cropped?.path ?? picked.path;
    final docs = await getTemporaryDirectory();
    final dest = p.join(docs.path, 'smart_pdf_temp');
    await Directory(dest).create(recursive: true);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(toCopy)}';
    final saved = await File(toCopy).copy(p.join(dest, fileName));
    setState(() => _images.add(saved.path));
  }

  void _removeAt(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _saveAndReturn() async {
    if (_images.isEmpty) return;
    Navigator.of(context).pop(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          IconButton(onPressed: _pickFromGallery, icon: const Icon(Icons.photo_library)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? Center(child: Text('No pages yet.\nUse the camera or pick from gallery.', textAlign: TextAlign.center))
                : ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _images.removeAt(oldIndex);
                        _images.insert(newIndex, item);
                      });
                    },
                    itemCount: _images.length,
                    itemBuilder: (ctx, idx) {
                      final pth = _images[idx];
                      return ListTile(
                        key: ValueKey(pth),
                        leading: Image.file(File(pth), width: 56, height: 76, fit: BoxFit.cover),
                        title: Text('Page ${idx + 1}'),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeAt(idx)),
                        onTap: () async {
                          // allow re-crop
                          final cropped = await ImageCropper().cropImage(sourcePath: pth);
                          if (cropped != null) {
                            final f = await File(cropped.path).copy(pth);
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ElevatedButton.icon(onPressed: _pickFromCamera, icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
                const SizedBox(width: 12),
                ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.photo), label: const Text('Gallery')),
                const Spacer(),
                ElevatedButton.icon(onPressed: _saveAndReturn, icon: const Icon(Icons.save), label: const Text('Save')),
              ],
            ),
          )
        ],
      ),
    );
  }
}