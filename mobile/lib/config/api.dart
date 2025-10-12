// lib/config/api.dart
// lib/config/api.dart
class ApiConfig {
  // TEMP: hardcode to prod to force-correct APK
  static const String base = 'https://ishi-api.onrender.com';

  static String healthzUrl() =>
      Uri.parse(base).replace(path: '/healthz').toString();

  static String readyUrl() =>
      Uri.parse(base).replace(path: '/ready').toString();

  static String newsUrl({int limit = 10, int debug = 0, String? source, String? q}) {
    final qp = <String, String>{
      'limit': '$limit',
      'debug': '$debug',
      if (source != null && source.isNotEmpty) 'source': source,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    return Uri.parse(base).replace(path: '/news', queryParameters: qp).toString();
  }

  static String predictUrl() =>
      Uri.parse(base).replace(path: '/predict').toString();
}
