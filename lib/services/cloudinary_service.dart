import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  // Configure these before using in development/testing.
  // Create an unsigned upload preset in your Cloudinary dashboard.
  static const String cloudName = 'dj0tz1vxm';
  static const String uploadPreset = 'unsigned_flowlink';

  Future<String> uploadImageBytes(
    Uint8List data, {
    String folder = 'flowlink/users',
    String fileName = 'profile.jpg',
  }) async {
    // Guard only when placeholders or empty values are present
    if (cloudName.isEmpty || uploadPreset.isEmpty ||
        cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UNSIGNED_UPLOAD_PRESET') {
      throw Exception('Configure CloudinaryService.cloudName and uploadPreset.');
    }
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    try {
      final mime = _guessMime(data);
      final ext = _extForMime(mime);
      final effectiveName = fileName.endsWith(ext) ? fileName : fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '') + ext;
      // Primary: multipart upload
      final req = http.MultipartRequest('POST', url);
      req.fields['upload_preset'] = uploadPreset;
      if (folder.isNotEmpty) req.fields['folder'] = folder;
      req.files.add(http.MultipartFile.fromBytes('file', data, filename: effectiveName));
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final secureUrl = (json['secure_url'] ?? json['url'] ?? '').toString();
        if (secureUrl.isEmpty) {
          throw Exception('Cloudinary upload failed: missing secure_url');
        }
        return secureUrl;
      }
      // Fallthrough to fallback with descriptive error
      String message = 'Cloudinary upload failed (${resp.statusCode})';
      try {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        message = m['error']?['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    } catch (_) {
      // Fallback: send as base64 data URI (helps with some browser/multipart issues)
      final mime = _guessMime(data);
      final dataUri = 'data:$mime;base64,${base64Encode(data)}';
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'upload_preset': uploadPreset,
          if (folder.isNotEmpty) 'folder': folder,
          'file': dataUri,
        },
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final secureUrl = (json['secure_url'] ?? json['url'] ?? '').toString();
        if (secureUrl.isEmpty) {
          throw Exception('Cloudinary upload failed: missing secure_url');
        }
        return secureUrl;
      }
      String message = 'Cloudinary upload failed (${resp.statusCode})';
      try {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        message = m['error']?['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}

String _guessMime(Uint8List bytes) {
  if (bytes.length >= 12) {
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'image/jpeg';
    // PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return 'image/png';
    // WEBP (RIFF....WEBP)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
  }
  return 'image/jpeg';
}

String _extForMime(String mime) {
  switch (mime) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    default:
      return '.jpg';
  }
}
