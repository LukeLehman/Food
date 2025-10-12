// lib/services/storage/local_storage.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart' as pp;

part 'local_storage.g.dart';

/// ===== Isar Model =====
@collection
class TestResult {
  Id id = Isar.autoIncrement;

  /// When the test was taken
  late DateTime timestamp;

  /// Prediction fields
  late bool anemic;
  late double score;

  /// Optional metadata
  String? imagePath;
  String? notes;
}

/// ===== Storage Facade (Isar with safe fallback) =====
///
/// Usage:
///   await LocalStore.addResult(result);
///   final items = await LocalStore.listResults(limit: 50);
///   await LocalStore.clearAll();
class LocalStore {
  // ---- Isar state ----
  static Isar? _isar;
  static bool _disabled = false; // when Isar init fails, switch to memory

  // ---- In-memory fallback store ----
  static final List<TestResult> _mem = <TestResult>[];

  /// Ensure Isar is opened (or mark disabled if unavailable).
  static Future<void> _ensureIsar() async {
    if (_disabled || _isar != null) return;

    try {
      if (kIsWeb) {
        // Native Isar isn't used on web here—fallback to memory.
        _disabled = true;
        debugPrint('Isar disabled on web; using in-memory store.');
        return;
      }

      final dir = await pp.getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [TestResultSchema],
        directory: dir.path,
      );
      debugPrint('Isar opened at: ${dir.path}');
    } catch (e) {
      debugPrint('Isar init failed, using in-memory fallback: $e');
      _disabled = true;
      _isar = null;
    }
  }

  /// Add one result; returns the assigned id (or synthetic id in memory).
  static Future<int> addResult(TestResult r) async {
    await _ensureIsar();
    if (_disabled || _isar == null) {
      final nextId = (_mem.isEmpty ? 1 : (_mem.last.id + 1));
      r.id = nextId;
      _mem.add(r);
      return nextId;
    }
    return _isar!.writeTxn(() => _isar!.testResults.put(r));
  }

  /// List results with newest first (up to [limit]).
  static Future<List<TestResult>> listResults({int limit = 100}) async {
    await _ensureIsar();
    if (_disabled || _isar == null) {
      final sorted = List<TestResult>.from(_mem)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sorted.take(limit).toList();
    }
    return _isar!.testResults.where().sortByTimestampDesc().limit(limit).findAll();
  }

  /// Clear everything.
  static Future<void> clearAll() async {
    await _ensureIsar();
    if (_disabled || _isar == null) {
      _mem.clear();
      return;
    }
    await _isar!.writeTxn(() async {
      await _isar!.testResults.clear();
    });
  }
}
