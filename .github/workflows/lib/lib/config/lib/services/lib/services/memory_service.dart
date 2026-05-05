import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const _key = 'conversation_history';
  static const _maxMessages = 30;

  static Future<void> addMessage(String role, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    list.add({"role": role, "content": content});
    if (list.length > _maxMessages) {
      list.removeRange(0, list.length - _maxMessages);
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<Map<String, String>>> getHistory({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    final start = list.length > limit ? list.length - limit : 0;
    return list.sublist(start).map((m) => {
      "role": m['role'].toString(),
      "content": m['content'].toString(),
    }).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
