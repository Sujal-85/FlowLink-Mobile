import 'dart:convert';
import 'package:http/http.dart' as http;

class AssistantMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  const AssistantMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class AssistantService {
  AssistantService._();
  static final AssistantService instance = AssistantService._();

  // Read from --dart-define at build/run time
  static const String _apiUrl = String.fromEnvironment('ASSISTANT_API_URL');
  static const String _apiKey = String.fromEnvironment('ASSISTANT_API_KEY');
  static const String _apiModel = String.fromEnvironment('ASSISTANT_MODEL', defaultValue: 'openai/gpt-4o-mini');
  static const String _title = String.fromEnvironment('ASSISTANT_TITLE', defaultValue: 'FlowLink');
  static const String _referer = String.fromEnvironment('ASSISTANT_REFERER');

  // For web, it's enough that the URL is present. The server holds the real key.
  bool get hasConfig => _apiUrl.isNotEmpty;

  // If user passes only the base domain (e.g., https://host.onrender.com),
  // default to '/api/chat' for the chat endpoint.
  String _normalizeApiUrl(String raw) {
    if (raw.isEmpty) return raw;
    try {
      final u = Uri.parse(raw);
      if ((u.path.isEmpty) || u.path == '/') {
        return Uri.parse('${u.origin}/api/chat').toString();
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Future<String> send(List<AssistantMessage> history) async {
    if (!hasConfig) {
      // Fallback local echo-like behavior when not configured
      final lastUser = history.lastWhere((m) => m.role == 'user', orElse: () => const AssistantMessage(role: 'user', content: ''));
      return "(Dev reply) You said: ${lastUser.content}";
    }

    try {
      final endpoint = _normalizeApiUrl(_apiUrl);
      final uri = Uri.parse(endpoint);
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      // Note: 'X-Title' and 'HTTP-Referer' are forwarded by the backend to OpenRouter.
      // We intentionally do not send them from the browser client to reduce CORS surface.

      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          // OpenAI/OpenRouter compatible body
          'model': _apiModel,
          'messages': history.map((m) => m.toJson()).toList(),
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        // Expect { reply: string } or {choices:[{message:{content}}]}
        if (data is Map && data['reply'] is String) {
          return data['reply'] as String;
        }
        if (data is Map && data['choices'] is List && data['choices'].isNotEmpty) {
          final choice = data['choices'][0];
          if (choice is Map && choice['message'] is Map && (choice['message']['content'] is String)) {
            return choice['message']['content'] as String;
          }
        }
        return 'Sorry, I could not understand the response.';
      } else {
        return 'Assistant error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }
}
