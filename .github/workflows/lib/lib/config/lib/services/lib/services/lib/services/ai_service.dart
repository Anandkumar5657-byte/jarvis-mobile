import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/personality.dart';
import 'memory_service.dart';

class AIService {
  String _apiKey = "";
  String _provider = "groq";
  String _model = "llama-3.3-70b-versatile";

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? '';
    _provider = prefs.getString('provider') ?? 'groq';
    _model = prefs.getString('model') ?? 'llama-3.3-70b-versatile';
  }

  Future<void> saveConfig({
    required String apiKey,
    required String provider,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
    await prefs.setString('provider', provider);
    await prefs.setString('model', model);
    _apiKey = apiKey;
    _provider = provider;
    _model = model;
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<Map<String, dynamic>> think(String userMessage) async {
    if (_apiKey.isEmpty) {
      return {
        "reply": "Sir, pehle settings mein API key add kar dijiye.",
        "tool": null,
        "requires_confirmation": false,
      };
    }

    await MemoryService.addMessage("user", userMessage);
    final history = await MemoryService.getHistory(limit: 10);

    try {
      String content;
      if (_provider == "openai") {
        content = await _callOpenAI(history);
      } else if (_provider == "gemini") {
        content = await _callGemini(history);
      } else {
        content = await _callGroq(history);
      }

      final data = _extractJson(content);
      await MemoryService.addMessage("assistant", jsonEncode(data));
      return data;
    } catch (e) {
      return {
        "reply": "Sir, AI brain mein dikkat: $e",
        "tool": null,
        "requires_confirmation": false,
      };
    }
  }

  Future<String> _callOpenAI(List<Map<String, String>> history) async {
    final messages = [
      {"role": "system", "content": JarvisPersonality.systemPrompt},
      ...history,
    ];
    final resp = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {"Authorization": "Bearer $_apiKey", "Content-Type": "application/json"},
      body: jsonEncode({
        "model": _model,
        "messages": messages,
        "temperature": 0.7,
        "response_format": {"type": "json_object"},
      }),
    );
    if (resp.statusCode != 200) throw "OpenAI ${resp.statusCode}";
    return jsonDecode(resp.body)['choices'][0]['message']['content'];
  }

  Future<String> _callGroq(List<Map<String, String>> history) async {
    final messages = [
      {"role": "system", "content": JarvisPersonality.systemPrompt},
      ...history,
    ];
    final resp = await http.post(
      Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
      headers: {"Authorization": "Bearer $_apiKey", "Content-Type": "application/json"},
      body: jsonEncode({
        "model": _model,
        "messages": messages,
        "temperature": 0.7,
        "response_format": {"type": "json_object"},
      }),
    );
    if (resp.statusCode != 200) throw "Groq ${resp.statusCode}: ${resp.body}";
    return jsonDecode(resp.body)['choices'][0]['message']['content'];
  }

  Future<String> _callGemini(List<Map<String, String>> history) async {
    final contents = history.map((h) => {
      "role": h['role'] == 'user' ? 'user' : 'model',
      "parts": [{"text": h['content']}]
    }).toList();
    final resp = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "system_instruction": {"parts": [{"text": JarvisPersonality.systemPrompt}]},
        "contents": contents,
        "generationConfig": {"temperature": 0.7, "responseMimeType": "application/json"},
      }),
    );
    if (resp.statusCode != 200) throw "Gemini ${resp.statusCode}";
    return jsonDecode(resp.body)['candidates'][0]['content']['parts'][0]['text'];
  }

  Map<String, dynamic> _extractJson(String text) {
    text = text.trim();
    if (text.startsWith("```")) {
      text = text.substring(3);
      if (text.startsWith("json")) text = text.substring(4);
      final endIdx = text.lastIndexOf("```");
      if (endIdx != -1) text = text.substring(0, endIdx);
      text = text.trim();
    }
    try {
      final d = jsonDecode(text);
      return {
        "reply": d['reply'] ?? "Theek hai sir.",
        "tool": d['tool'],
        "requires_confirmation": d['requires_confirmation'] ?? false,
      };
    } catch (_) {
      final start = text.indexOf("{");
      final end = text.lastIndexOf("}");
      if (start != -1 && end != -1) {
        try {
          return jsonDecode(text.substring(start, end + 1));
        } catch (_) {}
      }
      return {"reply": text, "tool": null, "requires_confirmation": false};
    }
  }
}
