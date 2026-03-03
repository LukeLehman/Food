import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Macro Tool'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, height: 300, width: 300, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _imageBytes = null;
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Clear Image'),
              ),
            ] else ...[
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Food Tracker',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload or take a photo to track the macros!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.image),
                label: const Text('Choose Photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}