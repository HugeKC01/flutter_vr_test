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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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
                    child: _imageFile != null ? Image.file(_imageFile!) : null,
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
              child: const Icon(Icons.image),
              tooltip: 'Pick another image',
            )
          : null,
    );
  }
}
