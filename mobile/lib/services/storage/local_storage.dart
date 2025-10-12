// lib/services/storage/local_storage.dart
import 'dart:async';

/// Simple in-memory model & store (no plugins / no codegen).
class TestResult {
  int id;
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

class LocalStore {
  static int _nextId = 1;
  static final List<TestResult> _mem = <TestResult>[];

  static Future<int> addResult(TestResult r) async {
    r.id = _nextId++;
    _mem.add(r);
    return r.id;
  }

  static Future<List<TestResult>> listResults({int limit = 100}) async {
    final sorted = List<TestResult>.from(_mem)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  static Future<void> clearAll() async {
    _mem.clear();
    _nextId = 1;
  }
}
