import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/sana_provider.dart';
import '../widgets/sana_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1A), Color(0xFF1E1E2E), Color(0xFF2D2B55)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<SanaProvider>(
                  builder: (context, sana, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SanaAvatar(
                          isListening: sana.isListening,
                          isSpeaking: sana.isSpeaking,
                          isProcessing: sana.isProcessing,
                        ),
                        const SizedBox(height: 30),
                        _buildStatus(sana),
                        const SizedBox(height: 20),
                        if (sana.lastCommand.isNotEmpty)
                          _buildBubble(sana.lastCommand, true),
                        if (sana.response.isNotEmpty)
                          _buildBubble(sana.response, false),
                        const Spacer(),
                        _buildQuickActions(context, sana),
                        const SizedBox(height: 20),
                        _buildMicButton(context, sana),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SANA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              Text('Your AI Assistant', style: TextStyle(color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white70),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(SanaProvider sana) {
    String text = 'Tap mic to speak';
    Color color = Colors.white70;
    
    if (sana.isListening) {
      text = 'Listening...';
      color = const Color(0xFF00BFA6);
    } else if (sana.isProcessing) {
      text = 'Processing...';
      color = Colors.orange;
    } else if (sana.isSpeaking) {
      text = 'Speaking...';
      color = const Color(0xFF6C63FF);
    }
    
    return Text(text, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w500));
  }

  Widget _buildBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF6C63FF).withOpacity(0.3) : const Color(0xFF00BFA6).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
          bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
        ),
        border: Border.all(color: isUser ? const Color(0xFF6C63FF) : const Color(0xFF00BFA6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUser ? Icons.person : Icons.android, color: isUser ? const Color(0xFF6C63FF) : const Color(0xFF00BFA6)),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }

  Widget _buildQuickActions(BuildContext context, SanaProvider sana) {
    final actions = [
      ('Files', Icons.file_copy, 'files'),
      ('Call', Icons.call, 'call'),
      ('Message', Icons.message, 'message'),
      ('Reminder', Icons.alarm, 'reminder'),
      ('Lights', Icons.lightbulb, 'lights'),
    ];
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final (label, icon, action) = actions[index];
          return GestureDetector(
            onTap: () => _showActionDialog(context, sana, action),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00BFA6)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicButton(BuildContext context, SanaProvider sana) {
    return GestureDetector(
      onTap: () {
        if (sana.isListening) {
          sana.stopListening();
        } else {
          sana.startListening();
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: sana.isListening 
                ? [Colors.red, Colors.redAccent] 
                : [const Color(0xFF6C63FF), const Color(0xFF00BFA6)],
          ),
          boxShadow: [
            BoxShadow(
              color: (sana.isListening ? Colors.red : const Color(0xFF6C63FF)).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          sana.isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, SanaProvider sana, String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Is feature ke liye mic daba kar command dein:\n\n${_getExampleCommand(action)}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getExampleCommand(String action) {
    switch (action) {
      case 'files':
        return '"File create notes.txt"\n"Files dikhao"\n"File delete karo"';
      case 'call':
        return '"Call 03001234567"\n"Phone Ammi ko"';
      case 'message':
        return '"Message Ali ko ke meeting ho gayi"';
      case 'reminder':
        return '"Reminder lagao dawai 8 baje"';
      case 'lights':
        return '"Lights on karo"\n"Lights off karo"';
      default:
        return 'Mic daba kar bolein';
    }
  }
}
