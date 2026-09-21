/// Non-web fallback for [downloadCsv] — there's no browser download surface
/// on mobile/desktop, so this is honest about that rather than pretending.
void downloadCsv(String filename, String csvContent) {
  throw UnsupportedError('CSV download is only available on web.');
}
