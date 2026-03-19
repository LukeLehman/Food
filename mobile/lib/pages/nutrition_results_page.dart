import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NutritionResultPage extends StatelessWidget {
  final String? imagePath; // now optional
  final String foodName;
  final Map<String, dynamic>? nutrition;

  const NutritionResultPage({
    super.key,
    this.imagePath,
    required this.foodName,
    required this.nutrition,
  });

  double? _getNutrient(String name) {
    final nutrients = nutrition?['foodNutrients'] ?? [];
    for (final n in nutrients) {
      if (n['nutrientName'] == name) {
        return (n['value'] as num?)?.toDouble();
      }
    }
    return null;
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return Image.network(
        imagePath!,
        height: 200,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath!),
        height: 200,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _getNutrient('Energy');
    final protein = _getNutrient('Protein');
    final carbs = _getNutrient('Carbohydrate, by difference');
    final fat = _getNutrient('Total lipid (fat)');
    final iron = _getNutrient('Iron, Fe');

    return Scaffold(
      appBar: AppBar(title: Text(foodName.toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 16),
            Text('Calories: ${calories ?? '--'} kcal'),
            Text('Protein: ${protein ?? '--'} g'),
            Text('Carbs: ${carbs ?? '--'} g'),
            Text('Fat: ${fat ?? '--'} g'),
            const SizedBox(height: 8),
            Text(
              'Iron: ${iron ?? '--'} mg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}