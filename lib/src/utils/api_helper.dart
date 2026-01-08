import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiHelper {
  static String getApiUrlFromKey(String key) {
    if (key.isEmpty) return 'https://agent-api.dev.nerdagent.ai';
    
    final prefix = key.length >= 3 ? key.substring(0, 3) : '';
    
    switch (prefix) {
      case 'DT_':
        return 'https://agent-api.dev.nerdagent.ai';
      case 'ST_':
        return 'https://agent-api.sandbox.nerdagent.ai';
      case 'UT_':
        return 'https://agent-api.uat.nerdagent.ai';
      case 'PN_':
        return 'https://agent-api.nerdagent.ai';
      default:
        return 'https://agent-api.dev.nerdagent.ai';
    }
  }

  static Map<String, String> getAuthHeaders({
    String? apikey,
    String? token,
  }) {
    final headers = <String, String>{
      'accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (apikey != null && apikey.isNotEmpty) {
      headers['agent-key'] = apikey;
    }

    return headers;
  }

  static String generateSessionId() {
    return 'session-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<Map<String, dynamic>?> loadAgentConfiguration({
  required String agentId,
  String? apikey,
  String? token,
  bool enableDebug = false,
}) async {
  try {
    if ((apikey == null || apikey.isEmpty) &&
        (token == null || token.isEmpty)) {
      if (enableDebug) log('[Chat Widget] No API key or token provided');
      return null;
    }

    if (agentId.isEmpty) {
      if (enableDebug) log('[Chat Widget] No agent ID provided');
      return null;
    }

    final baseApiUrl = getApiUrlFromKey(apikey ?? token ?? '');
    final configUrl = '$baseApiUrl/api/v1/chatbuilder/?agent_id=$agentId';

    if (enableDebug) log('[Chat Widget] Loading configuration from: $configUrl');

    final response = await http.get(
      Uri.parse(configUrl),
      headers: getAuthHeaders(apikey: apikey, token: token),
    );

    if (enableDebug) log('[Chat Widget] Config API response status: ${response.statusCode}');
    if (enableDebug) log('[Chat Widget] Config API raw body: ${response.body}');

    if (response.statusCode != 200) {
      if (enableDebug) log('[Chat Widget] Config API error: ${response.statusCode}');
      return null;
    }

    final decoded = json.decode(response.body);

    // If API returns a Map {...}
    if (decoded is Map<String, dynamic>) {
      final cfg = decoded['configuration'];
      if (cfg is Map<String, dynamic>) return cfg;
      // sometimes configuration itself might be a list; handle that
      if (cfg is List && cfg.isNotEmpty && cfg[0] is Map<String, dynamic>) {
        return cfg[0] as Map<String, dynamic>;
      }
      // fallback: return the whole decoded map if it seems like the configuration
      return decoded.cast<String, dynamic>();
    }

    // If API returns a List [...]
    if (decoded is List) {
      // try to find an item with a 'configuration' key
      for (final item in decoded) {
        if (item is Map<String, dynamic> && item.containsKey('configuration')) {
          final inner = item['configuration'];
          if (inner is Map<String, dynamic>) return inner;
          if (inner is List && inner.isNotEmpty && inner[0] is Map<String, dynamic>) {
            return inner[0] as Map<String, dynamic>;
          }
        }
        // if the item itself looks like a configuration map
        if (item is Map<String, dynamic> && item.containsKey('width') && item.containsKey('height')) {
          // heuristic — adjust to your shape
          return item;
        }
      }

      // nothing matched
      if (enableDebug) log('[Chat Widget] Unexpected JSON list shape; could not find configuration');
      return null;
    }

    // unknown JSON root
    if (enableDebug) log('[Chat Widget] Unexpected JSON root type: ${decoded.runtimeType}');
    return null;
  } catch (error, stack) {
    if (enableDebug) {
      log('[Chat Widget] Error loading configuration: $error');
      log(stack.toString());
    }
    return null;
  }
}


  static Future<Stream<String>> sendMessageStream({
    required String agentId,
    required String message,
    required String sessionId,
    String? apikey,
    String? token,
    bool enableDebug = false,
  }) async {
    final baseApiUrl = getApiUrlFromKey(apikey ?? token ?? '');
    final apiUrl = '$baseApiUrl/api/v1/agent/$agentId/invoke-smart/stream';

    final body = {
      'service_provider': 'strandsagent',
      'prompt': message,
      'session_id': sessionId,
      'response_format': 'text',
    };

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers.addAll(getAuthHeaders(apikey: apikey, token: token));
    request.fields['body'] = json.encode(body);

    if (enableDebug) {
      log('[Chat Widget] Sending message to: $apiUrl');
    }

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      if (enableDebug) {
        log('[Chat Widget] API error: ${streamedResponse.statusCode}');
      }
      throw Exception('HTTP error! status: ${streamedResponse.statusCode}');
    }

    return streamedResponse.stream.transform(utf8.decoder);
  }

  static Future<Map<String, dynamic>?> sendFileMessage({
    required String agentId,
    required String fileName,
    required List<int> fileBytes,
    required String sessionId,
    String? message,
    String? apikey,
    String? token,
    bool enableDebug = false,
  }) async {
    try {
      final baseApiUrl = getApiUrlFromKey(apikey ?? token ?? '');
      final apiUrl = '$baseApiUrl/api/v1/agent/$agentId/invoke';

      final body = {
        'service_provider': 'strandsagent',
        'prompt': message ?? 'User uploaded file: $fileName',
        'session_id': sessionId,
        'response_format': 'text',
      };

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll(getAuthHeaders(apikey: apikey, token: token));
      request.fields['body'] = json.encode(body);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      if (enableDebug) {
        log('[Chat Widget] Uploading file: $fileName');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        if (enableDebug) {
          log('[Chat Widget] File upload error: ${response.statusCode}');
        }
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final result = json.decode(response.body) as Map<String, dynamic>;
      return result;
    } catch (error) {
      if (enableDebug) {
        log('[Chat Widget] File upload exception: $error');
      }
      rethrow;
    }
  }
}