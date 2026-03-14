import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SanaAvatar extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;

  const SanaAvatar({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening || isSpeaking)
            ...List.generate(3, (i) {
              return Container(
                width: 220 + (i * 40).toDouble(),
                height: 220 + (i * 40).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getColor().withOpacity(0.3 - (i * 0.1)),
                    width: 2,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: Duration(milliseconds: 1500))
              .fadeOut();
            }),
          
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00BFA6)]),
              boxShadow: [
                BoxShadow(color: Color(0xFF6C63FF), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Icon(_getIcon(), size: 80, color: Colors.white),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: const Duration(milliseconds: 2000)),
          
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _getColor(), width: 3),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (isListening) return Icons.mic;
    if (isSpeaking) return Icons.record_voice_over;
    if (isProcessing) return Icons.memory;
    return Icons.face;
  }

  Color _getColor() {
    if (isListening) return const Color(0xFF00BFA6);
    if (isSpeaking) return const Color(0xFF6C63FF);
    if (isProcessing) return Colors.orange;
    return Colors.white24;
  }
}
