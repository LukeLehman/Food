// lib/services/storage/local_storage.dart
import 'dart:async';

/// Plain Dart model (no Isar annotations)
class TestResult {
  int id; // synthetic auto-increment
  DateTime timestamp;
  bool anemic;
  double score;
  String? imagePath;
  String? notes;

  TestResult({
    this.id = 0,
    required this.timestamp,
    required this.anemic,
    required this.score,
    this.imagePath,
    this.notes,
  });
}

/// In-memory store that mimics the previous Isar facade API.
class LocalStore {
  static final List<TestResult> _mem = <TestResult>[];
  static int _nextId = 1;

  /// Add one result; returns assigned id
  static Future<int> addResult(TestResult r) async {
    r.id = _nextId++;
    _mem.add(r);
    return r.id;
  }

  /// List results with newest first (up to [limit])
  static Future<List<TestResult>> listResults({int limit = 100}) async {
    final copy = List<TestResult>.from(_mem)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy.take(limit).toList();
  }

  /// Clear everything
  static Future<void> clearAll() async {
    _mem.clear();
    _nextId = 1;
  }
}