import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'nutrition_results_page.dart';

class FoodPage extends StatefulWidget {
  final CameraDescription camera;

  const FoodPage({super.key, required this.camera});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // NEW: controller for manual food input
  final TextEditingController _foodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Tracking Camera')),
      body: Column(
        children: [
          // Manual input for desktop/web
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _foodController,
                      decoration: const InputDecoration(
                        labelText: 'Enter food name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final food = _foodController.text.trim();
                      if (food.isEmpty) return;

                      final nutrition =
                          await FoodAnalyzer.fetchNutrition(food);

                      if (!mounted || nutrition == null) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NutritionResultPage(
                            imagePath: '', // no image
                            foodName: food,
                            nutrition: nutrition,
                          ),
                        ),
                      );
                    },
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
          // Camera preview for mobile
          Expanded(
            child: FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          await _initializeControllerFuture;
          final image = await _controller.takePicture();

          if (!mounted) return;

          // Detect the food item
          final food = await FoodAnalyzer.detectFood(image.path);
          if (food == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not detect food item.')),
            );
            return;
          }

          final nutrition = await FoodAnalyzer.fetchNutrition(food);
          if (nutrition == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NutritionResultPage(
                imagePath: image.path,
                foodName: food,
                nutrition: nutrition,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FoodAnalyzer {
  static final ImageLabeler _labeler =
      ImageLabeler(options: ImageLabelerOptions());

  static Future<String?> detectFood(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler.processImage(inputImage);

    if (labels.isEmpty) return null;

    // Best guess: highest confidence label
    labels.sort((a, b) => b.confidence.compareTo(a.confidence));
    return labels.first.label.toLowerCase();
  }

  static Future<Map<String, dynamic>?> fetchNutrition(String food) async {
    const apiKey = '9KaBngBH5d2bAT8kT3X57rl4ZyhOXPDcI8d1y6ag';

    final uri = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search'
      '?query=$food&api_key=$apiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['foods'] == null || data['foods'].isEmpty) return null;

    return data['foods'][0];
  }
}