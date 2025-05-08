import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class VrImageViewer extends StatefulWidget {
  const VrImageViewer({super.key});

  @override
  State<VrImageViewer> createState() => _VrImageViewerState();
}

class _VrImageViewerState extends State<VrImageViewer> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
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

  void _onViewChanged(double longitude, double latitude, double zoom) {
    setState(() {
      _longitude = longitude;
      _latitude = latitude;
      _zoom = zoom;
    });
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
                : PanoramaViewer(
                    longitude: _longitude,
                    latitude: _latitude,
                    zoom: _zoom,
                    onViewChanged: _onViewChanged,
                    child: Image.file(_imageFile!),
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
        ],
      ),
      floatingActionButton: _imageFile != null
          ? FloatingActionButton(
              onPressed: _pickImage,
              tooltip: 'Pick another image',
              child: const Icon(Icons.image),
            )
          : null,
    );
  }
}
