// lib/pages/camera_page.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

/// Read the backend base URL from a build-time define:
/// flutter run/build ... --dart-define=API_BASE_URL=https://ishi-api.onrender.com
const String _apiBase =
    String.fromEnvironment('API_BASE_URL', defaultValue: '');

Uri _joinPath(Uri base, String path) {
  if (path.startsWith('/')) {
    return base.replace(path: path, query: '');
  }
  final p = base.path.endsWith('/') ? '${base.path}$path' : '${base.path}/$path';
  return base.replace(path: p, query: '');
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _result;
  String? _detail;
  bool _loading = false;
  List<Map<String, String>> _history = [];

  Uri? get _apiBaseUri {
    if (_apiBase.isEmpty) return null;
    final u = Uri.tryParse(_apiBase);
    return (u == null || !u.hasScheme) ? null : u;
  }

  Uri? _predictUri() => _apiBaseUri == null ? null : _joinPath(_apiBaseUri!, '/predict');
  Uri? _healthUri() => _apiBaseUri == null ? null : _joinPath(_apiBaseUri!, '/health');

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _detail = null;
    });
  }

  Future<void> _takePhoto() async {
    // Works on Android/iOS; on web it falls back to file input.
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _detail = null;
    });
  }

  Future<void> _submitImage() async {
    if (_imageBytes == null) return;
    final uri = _predictUri();
    if (uri == null) {
      setState(() {
        _result = 'API not configured';
        _detail = 'Pass --dart-define=API_BASE_URL=https://your-api';
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final req = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'image', // server expects "image"
          _imageBytes!,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final m = jsonDecode(body) as Map<String, dynamic>;
        final isAnemic = m['anemic'] == true;
        final score = (m['score'] is num) ? (m['score'] as num).toDouble() : 0.0;
        final pct = (score * 100).toStringAsFixed(1);
        final cropper = (m['cropper'] ?? 'n/a').toString();

        final resultText = isAnemic ? 'Anemic' : 'Not Anemic';
        final detailText = 'Score: $pct% • Cropper: $cropper';

        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        final entry = {'timestamp': ts, 'result': resultText};

        // Persist history
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _result = resultText;
          _detail = detailText;
          _history.insert(0, entry);
        });
        await prefs.setString('ishi_test_history', jsonEncode(_history));
      } else {
        setState(() {
          _result = 'Error ${res.statusCode}';
          _detail = body;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Network error';
        _detail = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testHealth() async {
    final u = _healthUri();
    if (u == null) {
      setState(() {
        _result = 'API not configured';
        _detail = 'Pass --dart-define=API_BASE_URL=https://your-api';
      });
      return;
    }
    try {
      final r = await http.get(u);
      setState(() {
        _result = 'Health ${r.statusCode}';
        _detail = r.body;
      });
    } catch (e) {
      setState(() {
        _result = 'Health error';
        _detail = e.toString();
      });
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ishi_test_history');
    if (saved != null) {
      final decoded = jsonDecode(saved);
      final list = (decoded as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      setState(() {
        _history = list;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final api = _apiBaseUri;
    final apiText = api == null
        ? 'API: (not set)'
        : 'API: ${api.scheme}://${api.host}${api.hasPort ? ':${api.port}' : ''}${api.path}';

    return Scaffold(
      appBar: AppBar(title: const Text('Anemia Checker')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Connectivity row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(onPressed: _testHealth, child: const Text('Test API')),
                    const SizedBox(width: 12),
                    Flexible(
                      child: SelectableText(
                        apiText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'About Anemia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Anemia is a condition where you lack enough healthy red blood cells to carry adequate oxygen to your body\'s tissues. Detecting it early can help prevent fatigue, weakness, and more serious complications.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_imageBytes != null) ...[
                  const Text('Selected Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_imageBytes!, height: 200),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_loading)
                  const CircularProgressIndicator()
                else if (_result != null)
                  Card(
                    color: _result == 'Anemic' ? Colors.red[100] : Colors.green[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _result!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _result == 'Anemic' ? Colors.red[800] : Colors.green[800],
                            ),
                          ),
                          if (_detail != null) ...[
                            const SizedBox(height: 6),
                            Text(_detail!, style: const TextStyle(fontSize: 14)),
                          ]
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _pickFromGallery,
                      child: const Text('Upload Eyelid Image'),
                    ),
                    ElevatedButton(
                      onPressed: _takePhoto,
                      child: Text(kIsWeb ? 'Capture (Browser Prompt)' : 'Capture from Camera'),
                    ),
                    ElevatedButton(
                      onPressed: _imageBytes == null || _loading ? null : _submitImage,
                      child: const Text('Check for Anemia'),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                if (_history.isNotEmpty) ...[
                  const Divider(),
                  const Text('Test History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._history
                      .map((entry) => ListTile(
                            leading: Icon(
                              entry['result'] == 'Anemic' ? Icons.warning : Icons.check_circle,
                              color: entry['result'] == 'Anemic' ? Colors.red : Colors.green,
                            ),
                            title: Text(entry['result']!),
                            subtitle: Text(entry['timestamp']!),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
