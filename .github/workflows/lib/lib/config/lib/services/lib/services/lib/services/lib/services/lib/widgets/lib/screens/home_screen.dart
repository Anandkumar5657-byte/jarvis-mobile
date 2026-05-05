import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../services/tools_service.dart';
import '../widgets/jarvis_orb.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voice = VoiceService();
  final AIService _ai = AIService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _continuousMode = true;
  String _userText = "";

  final List<Map<String, String>> _chat = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initialize();
  }

  Future<void> _initialize() async {
    await _voice.init();
    await _ai.loadConfig();
    if (!_ai.isConfigured) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _openSettings(firstTime: true);
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _isSpeaking = true);
      await _voice.speak("Jarvis online sir. Aaj main aapki kya madad kar sakta hoon?");
      setState(() => _isSpeaking = false);
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isSpeaking || _isThinking) return;
    if (!_ai.isConfigured) return;

    setState(() {
      _isListening = true;
      _userText = "";
    });

    final text = await _voice.listen(
      timeout: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      onPartial: (t) => setState(() => _userText = t),
    );

    setState(() => _isListening = false);

    if (text.isNotEmpty) {
      await _processInput(text);
    } else if (_continuousMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      _startListening();
    }
  }

  Future<void> _processInput(String input) async {
    setState(() {
      _isThinking = true;
      _chat.add({"role": "user", "text": input});
    });

    final plan = await _ai.think(input);
    setState(() => _isThinking = false);

    final reply = plan['reply']?.toString() ?? "";
    final tool = plan['tool'];
    final needsConfirm = plan['requires_confirmation'] == true;

    if (reply.isNotEmpty) {
      setState(() {
        _chat.add({"role": "jarvis", "text": reply});
        _isSpeaking = true;
      });
      await _voice.speak(reply);
      setState(() => _isSpeaking = false);
    }

    if (tool != null && tool is Map) {
      final toolName = tool['name']?.toString() ?? '';
      final toolArgs = Map<String, dynamic>.from(tool['args'] ?? {});

      if (needsConfirm) {
        final confirmText = await _voice.listen(
          timeout: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 2),
        );
        final confirmed = ['haan', 'yes', 'ha', 'ok', 'okay', 'kar do', 'karo']
            .any((w) => confirmText.toLowerCase().contains(w));
        if (!confirmed) {
          setState(() => _isSpeaking = true);
          await _voice.speak("Cancel kar diya sir.");
          setState(() => _isSpeaking = false);
          if (_continuousMode) _startListening();
          return;
        }
      }

      await ToolsService.execute(toolName, toolArgs);
    }

    if (_continuousMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      _startListening();
    }
  }

  void _openSettings({bool firstTime = false}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    await _ai.loadConfig();
    if (firstTime && _ai.isConfigured) {
      setState(() => _isSpeaking = true);
      await _voice.speak("Jarvis online sir. Aaj main aapki kya madad kar sakta hoon?");
      setState(() => _isSpeaking = false);
      _startListening();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _voice.stop();
    _voice.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF001D3D), Color(0xFF000814)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _ai.isConfigured ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_ai.isConfigured ? Colors.green : Colors.red).withOpacity(0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("JARVIS",
                            style: TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF00D4FF)),
                      onPressed: () => _openSettings(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chat.length,
                  itemBuilder: (context, i) {
                    final msg = _chat[_chat.length - 1 - i];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF0077FF).withOpacity(0.3)
                                    : const Color(0xFF00D4FF).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUser ? const Color(0xFF0077FF) : const Color(0xFF00D4FF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_userText.isNotEmpty && _isListening)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_userText,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center),
                ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: JarvisOrb(
                  isListening: _isListening,
                  isSpeaking: _isSpeaking,
                  isThinking: _isThinking,
                  onTap: () {
                    if (_isListening) {
                      _voice.stopListening();
                      setState(() => _isListening = false);
                    } else if (_isSpeaking) {
                      _voice.stop();
                      setState(() => _isSpeaking = false);
                    } else {
                      _startListening();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Continuous Mode", style: TextStyle(color: Colors.white70)),
                    Switch(
                      value: _continuousMode,
                      activeColor: const Color(0xFF00D4FF),
                      onChanged: (v) => setState(() => _continuousMode = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
