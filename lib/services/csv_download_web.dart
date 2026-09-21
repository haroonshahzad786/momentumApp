import 'dart:html' as html;

/// Real browser download via a temporary object URL + a synthetic
/// anchor click — the standard `dart:html` pattern for client-generated
/// file downloads.
void downloadCsv(String filename, String csvContent) {
  final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
