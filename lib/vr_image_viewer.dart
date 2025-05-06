import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:flutter/services.dart';

class VrImageViewer extends StatefulWidget {
  const VrImageViewer({super.key});

  @override
  State<VrImageViewer> createState() => _VrImageViewerState();
}

class _VrImageViewerState extends State<VrImageViewer> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isVrMode = false;
  double _longitude = 0;
  double _latitude = 0;
  double _zoom = 1;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _toggleVrMode() async {
    if (!_isVrMode) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {
      _isVrMode = !_isVrMode;
    });
  }

  void _onViewChanged(double longitude, double latitude, double zoom) {
    setState(() {
      _longitude = longitude;
      _latitude = latitude;
      _zoom = zoom;
    });
  }

  @override
  void dispose() {
    // Restore orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _imageFile == null
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Image'),
                  )
                : _isVrMode
                    ? Row(
                        children: [
                          Expanded(
                            child: PanoramaViewer(
                              child: Image.file(_imageFile!),
                              longitude: _longitude,
                              latitude: _latitude,
                              zoom: _zoom,
                              onViewChanged: _onViewChanged,
                            ),
                          ),
                          Expanded(
                            child: PanoramaViewer(
                              child: Image.file(_imageFile!),
                              longitude: _longitude,
                              latitude: _latitude,
                              zoom: _zoom,
                              onViewChanged: _onViewChanged,
                            ),
                          ),
                        ],
                      )
                    : PanoramaViewer(
                        child: Image.file(_imageFile!),
                        longitude: _longitude,
                        latitude: _latitude,
                        zoom: _zoom,
                        onViewChanged: _onViewChanged,
                      ),
          ),
          Positioned(
            top: 32,
            left: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (_imageFile != null)
            Positioned(
              top: 32,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(_isVrMode ? Icons.close : Icons.vrpano, color: Colors.white),
                  onPressed: _toggleVrMode,
                  tooltip: _isVrMode ? 'Exit VR Mode' : 'Enter VR Mode',
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _imageFile != null
          ? FloatingActionButton(
              onPressed: _pickImage,
              child: const Icon(Icons.image),
              tooltip: 'Pick another image',
            )
          : null,
    );
  }
}
