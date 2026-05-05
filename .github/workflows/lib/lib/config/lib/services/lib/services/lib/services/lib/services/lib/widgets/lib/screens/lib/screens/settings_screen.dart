import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  String _provider = 'groq';
  String _model = 'llama-3.3-70b-versatile';

  final Map<String, List<String>> _models = {
    'openai': ['gpt-4o-mini', 'gpt-4o'],
    'gemini': ['gemini-1.5-flash', 'gemini-1.5-pro'],
    'groq': ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
  };

  final Map<String, String> _info = {
    'openai': 'Paid - Best quality\nplatform.openai.com',
    'gemini': 'Free tier\naistudio.google.com',
    'groq': 'FREE & FASTEST ⚡\nconsole.groq.com',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyCtrl.text = prefs.getString('api_key') ?? '';
      _provider = prefs.getString('provider') ?? 'groq';
      _model = prefs.getString('model') ?? _models[_provider]!.first;
    });
  }

  Future<void> _save() async {
    if (_apiKeyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter API key")));
      return;
    }
    await AIService().saveConfig(
      apiKey: _apiKeyCtrl.text.trim(),
      provider: _provider,
      model: _model,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Saved!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      appBar: AppBar(
        title: const Text("JARVIS Settings", style: TextStyle(color: Color(0xFF00D4FF), letterSpacing: 3)),
        backgroundColor: const Color(0xFF001D3D),
        iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text("AI PROVIDER", style: TextStyle(color: Color(0xFF00D4FF), letterSpacing: 3)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D4FF)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _provider,
                isExpanded: true,
                dropdownColor: const Color(0xFF001D3D),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white),
                items: _models.keys
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() {
                  _provider = v!;
                  _model = _models[v]!.first;
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(_info[_provider] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 24),
            const Text("API KEY", style: TextStyle(color: Color(0xFF00D4FF), letterSpacing: 3)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Paste API key",
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("MODEL", style: TextStyle(color: Color(0xFF00D4FF), letterSpacing: 3)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D4FF)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _models[_provider]!.contains(_model) ? _model : _models[_provider]!.first,
                isExpanded: true,
                dropdownColor: const Color(0xFF001D3D),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white),
                items: _models[_provider]!
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _model = v!),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _save,
              child: const Text("SAVE & ACTIVATE",
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3)),
            ),
          ],
        ),
      ),
    );
  }
}
