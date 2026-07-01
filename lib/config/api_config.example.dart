// TEMPLATE — copy this file to `api_config.dart` (same folder) and set the real
// backend secret. `api_config.dart` is gitignored so the secret is never
// committed. The app reads `ApiConfig.secret` for every cloud-function call.
class ApiConfig {
  /// Shared secret sent to the Momentum cloud functions (functions-flutter).
  static const String secret = 'YOUR_BACKEND_SECRET_HERE';
}
