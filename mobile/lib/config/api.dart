// lib/config/api.dart
class ApiConfig {
  static const String base = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://ishi-api.onrender.com',
);

// Add to ApiConfig class:
static const String minAppVersion = String.fromEnvironment(
  'MIN_APP_VERSION',
  defaultValue: '1.0.0',
);

static const String storeUrl = String.fromEnvironment(
  'APP_STORE_URL',
  // TODO: replace when you have a Play Store URL
  defaultValue: 'https://ironstronginitiative.com/app',
);

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
