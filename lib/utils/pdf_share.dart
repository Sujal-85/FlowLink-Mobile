import 'dart:typed_data';
import 'pdf_share_stub.dart'
  if (dart.library.html) 'pdf_share_web.dart'
  if (dart.library.io) 'pdf_share_io.dart' as pdf_share_impl;

Future<void> shareOrDownloadPdf(Uint8List bytes, String filename) {
  return pdf_share_impl.shareOrDownloadPdf(bytes, filename);
}
