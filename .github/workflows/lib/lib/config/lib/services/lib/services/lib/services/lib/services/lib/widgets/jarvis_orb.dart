import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

class JarvisOrb extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final VoidCallback onTap;

  const JarvisOrb({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isThinking,
    required this.onTap,
  });

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.isListening) return const Color(0xFF00FF88);
    if (widget.isSpeaking) return const Color(0xFF00D4FF);
    if (widget.isThinking) return const Color(0xFFFFAA00);
    return const Color(0xFF0077FF);
  }

  String get _statusText {
    if (widget.isListening) return "LISTENING";
    if (widget.isSpeaking) return "SPEAKING";
    if (widget.isThinking) return "THINKING";
    return "TAP TO SPEAK";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarGlow(
          glowColor: _color,
          glowRadiusFactor: 0.5,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          animate: widget.isListening || widget.isSpeaking || widget.isThinking,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _color.withOpacity(0.9),
                    _color.withOpacity(0.4),
                    Colors.black,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.mic, size: 80, color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          _statusText,
          style: TextStyle(color: _color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
      ],
    );
  }
}
