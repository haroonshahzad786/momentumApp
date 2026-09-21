// Triggers a browser file download for `csvContent` named `filename`.
//
// Web-only (Admin Panel bulk "Export selected" — #A2.2): conditional export
// picks the real `dart:html` implementation when compiling for web, and a
// stub that throws UnsupportedError everywhere else (mobile builds can
// reach the admin screens too, per momentum_home.dart's wiring, so this
// must not fail to compile there — it just can't actually download).
export 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';
