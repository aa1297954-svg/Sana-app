import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class SanaProvider extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final _uuid = const Uuid();
  final _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _lastCommand = '';
  String _response = '';
  List<Map<String, dynamic>> _history = [];

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isProcessing => _isProcessing;
  String get lastCommand => _lastCommand;
  String get response => _response;
  List<Map<String, dynamic>> get history => _history;

  SanaProvider() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.2);
    await _tts.setVolume(1.0);
    
    await _speech.initialize();
    
    tz_data.initializeTimeZones();
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    
    await _loadHistory();
    
    await Future.delayed(const Duration(seconds: 1));
    await speak('Asalam o alaikum! Main Sana hoon, aapki personal assistant. Main aapke liye kya kar sakti hoon?');
  }

  Future<void> startListening() async {
    if (_isListening) return;
    
    _isListening = true;
    notifyListeners();
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _lastCommand = result.recognizedWords;
          _isListening = false;
          notifyListeners();
          _processCommand(_lastCommand);
        }
      },
      localeId: 'ur_PK',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    _response = text;
    _isSpeaking = true;
    notifyListeners();
    
    await _tts.speak(text);
    await Future.delayed(Duration(milliseconds: text.length * 80));
    
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> _processCommand(String cmd) async {
    _isProcessing = true;
    notifyListeners();
    
    await _addToHistory('user', cmd);
    
    String response = '';
    String c = cmd.toLowerCase();
    
    if (c.contains('salam') || c.contains('hello') || c.contains('hi')) {
      response = 'Walaykum Asalam! Main Sana, aapki madad ke liye hazir. Aaj kya karna hai?';
    }
    else if (c.contains('kaun') || c.contains('who') || c.contains('name')) {
      response = 'Main Sana hoon, aapki AI assistant. Main Urdu aur English samajhti hoon. Files, calls, reminders sab handle kar sakti hoon!';
    }
    else if (c.contains('time') || c.contains('waqt') || c.contains('kitne baje')) {
      final now = DateTime.now();
      response = 'Abhi waqt hai ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    }
    else if (c.contains('date') || c.contains('din') || c.contains('tarikh')) {
      response = 'Aaj ${DateFormat.yMMMMd().format(DateTime.now())} hai';
    }
    else if (c.contains('file') && (c.contains('create') || c.contains('banao'))) {
      response = await _createFile(c);
    }
    else if (c.contains('file') && (c.contains('delete') || c.contains('hatao'))) {
      response = await _deleteFile(c);
    }
    else if (c.contains('files') || c.contains('file dikhao') || c.contains('list')) {
      response = await _listFiles();
    }
    else if (c.contains('share') || c.contains('bhejo')) {
      response = await _shareFile();
    }
    else if (c.contains('call') || c.contains('phone') || c.contains('dial')) {
      response = await _makeCall(c);
    }
    else if (c.contains('message') || c.contains('sms')) {
      response = await _sendMessage(c);
    }
    else if (c.contains('remind') || c.contains('alarm') || c.contains('yaad')) {
      response = await _setReminder(c);
    }
    else if (c.contains('light') || c.contains('batti')) {
      if (c.contains('on') || c.contains('jalao')) {
        response = 'Lights on kar di hain';
      } else {
        response = 'Lights off kar di hain';
      }
    }
    else if (c.contains('prompt') || c.contains('generate')) {
      final topic = c.replaceAll(RegExp(r'prompt|generate|likho|ke liye'), '').trim();
      response = _generatePrompt(topic);
    }
    else if (c.contains('email') || c.contains('mail')) {
      response = _writeEmail(c);
    }
    else if (c.contains('weather') || c.contains('mosam') || c.contains('mausam')) {
      response = 'Aaj ka mausam: 24°C, halki hawa, dhoop nikli hui';
    }
    else if (c.contains('news') || c.contains('khabar')) {
      response = 'Aaj ki khabrein: Technology mein nayi advancements, Pakistan mein acha mausam';
    }
    else if (c.contains('joke') || c.contains('lateefa')) {
      response = 'Teacher: Computer ko Urdu mein kya kehte hain? Student: Sust dimaagh!';
    }
    else if (c.contains('motivate') || c.contains('udaas') || c.contains('himmat')) {
      response = 'Yaad rakhein, har mushkil ke baad asani hai! Aap strong hain! 💪';
    }
    else if (c.contains('thanks') || c.contains('shukria') || c.contains('thank you')) {
      response = 'Koi baat nahi! Main hamesha aapki madad ke liye hazir hoon. 😊';
    }
    else {
      response = "Main samajh gayi aap '$cmd' ke baare mein baat kar rahe hain";
    }
    
    await _addToHistory('sana', response);
    _isProcessing = false;
    notifyListeners();
    await speak(response);
  }

  Future<String> _createFile(String cmd) async {
    try {
      final name = _extractFilename(cmd);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString('Created by SANA on ${DateTime.now()}\n\n');
      
      final box = Hive.box('files');
      final files = List<Map>.from(box.get('list', defaultValue: []));
      files.add({'name': name, 'path': file.path, 'date': DateTime.now().toIso8601String()});
      await box.put('list', files);
      
      return 'File $name create kar di hai';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _deleteFile(String cmd) async {
    try {
      final name = _extractFilename(cmd);
      final box = Hive.box('files');
      final files = List<Map>.from(box.get('list', defaultValue: []));
      
      final idx = files.indexWhere((f) => f['name'] == name);
      if (idx != -1) {
        final file = File(files[idx]['path']);
        if (await file.exists()) await file.delete();
        files.removeAt(idx);
        await box.put('list', files);
        return 'File $name delete kar di hai';
      }
      return 'File nahi mili';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _listFiles() async {
    final box = Hive.box('files');
    final files = List<Map>.from(box.get('list', defaultValue: []));
    if (files.isEmpty) return 'Koi file nahi hai';
    return 'Aapki files:\n' + files.map((f) => '📄 ${f['name']}').join('\n');
  }

  Future<String> _shareFile() async {
    final box = Hive.box('files');
    final files = List<Map>.from(box.get('list', defaultValue: []));
    if (files.isEmpty) return 'Share karne ke liye koi file nahi';
    
    await Share.shareXFiles([XFile(files.last['path'])]);
    return 'File share kar di';
  }

  Future<String> _makeCall(String cmd) async {
    final status = await Permission.phone.request();
    if (!status.isGranted) return 'Phone permission nahi milli';
    
    final name = _extractName(cmd);
    if (name.isEmpty) return 'Kisko call karna hai?';
    
    if (RegExp(r'^[\d+]').hasMatch(name)) {
      await FlutterPhoneDirectCaller.callNumber(name);
      return '$name ko call lag rahi hai';
    }
    
    return '$name ko call karne ke liye number dial karein';
  }

  Future<String> _sendMessage(String cmd) async {
    final name = _extractName(cmd);
    String msg = '';
    
    if (cmd.contains(' ke ')) {
      msg = cmd.split(' ke ').last;
    } else if (cmd.contains(' that ')) {
      msg = cmd.split(' that ').last;
    }
    
    if (name.isEmpty) return 'Kisko message karna hai?';
    if (msg.isEmpty) return 'Message kya hai?';
    
    final uri = Uri.parse('sms:${_isNumber(name) ? name : ''}?body=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return 'SMS app open ho gaya';
    }
    return 'Message bhejne mein error';
  }

  Future<String> _setReminder(String cmd) async {
    final task = cmd.replaceAll(RegExp(r'remind|alarm|yaad|set'), '').trim();
    final time = _parseTime(cmd);
    
    if (task.isEmpty) return 'Kya yaad dilana hai?';
    if (time == null) return 'Kab yaad dilana hai?';
    
    await _notifications.zonedSchedule(
      _uuid.v4().hashCode,
      'SANA Reminder',
      task,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('sana', 'SANA', importance: Importance.high),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    final box = Hive.box('reminders');
    final list = List<Map>.from(box.get('list', defaultValue: []));
    list.add({'task': task, 'time': time.toIso8601String()});
    await box.put('list', list);
    
    return 'Reminder set: $task at ${DateFormat.jm().format(time)}';
  }

  String _generatePrompt(String topic) {
    if (topic.isEmpty) return 'Kis topic ke liye prompt chahiye?';
    return 'Prompt for $topic: Create highly detailed, professional $topic, 8k resolution, perfect lighting, photorealistic';
  }

  String _writeEmail(String cmd) {
    final topic = cmd.replaceAll(RegExp(r'email|mail|write|likho'), '').trim();
    return 'Subject: Regarding ${topic.isEmpty ? 'Meeting' : topic}\n\nDear Sir/Madam,\n\nI hope this email finds you well...\n\nBest regards';
  }

  String _extractFilename(String cmd) {
    final match = RegExp(r'(?:create|banayein|banao)\s+(\S+)').firstMatch(cmd);
    String name = match?.group(1) ?? 'file.txt';
    if (!name.contains('.')) name += '.txt';
    return name;
  }

  String _extractName(String cmd) {
    for (var p in [RegExp(r'call\s+(\w+)'), RegExp(r'phone\s+(\w+)'), RegExp(r'message\s+(\w+)')]) {
      final m = p.firstMatch(cmd);
      if (m != null) return m.group(1) ?? '';
    }
    return '';
  }

  DateTime? _parseTime(String input) {
    input = input.toLowerCase();
    final now = DateTime.now();
    
    if (input.contains('subah')) return DateTime(now.year, now.month, now.day, 8, 0);
    if (input.contains('dopahar')) return DateTime(now.year, now.month, now.day, 13, 0);
    if (input.contains('shaam')) return DateTime(now.year, now.month, now.day, 18, 0);
    if (input.contains('raat')) return DateTime(now.year, now.month, now.day, 21, 0);
    
    final match = RegExp(r'(\d{1,2}):?(\d{2})?').firstMatch(input);
    if (match != null) {
      int h = int.parse(match.group(1)!);
      int m = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      var t = DateTime(now.year, now.month, now.day, h, m);
      if (t.isBefore(now)) t = t.add(const Duration(days: 1));
      return t;
    }
    return null;
  }

  bool _isNumber(String s) => RegExp(r'^[\d+]').hasMatch(s);

  Future<void> _addToHistory(String sender, String msg) async {
    final box = Hive.box('memory');
    _history = List<Map>.from(box.get('chat', defaultValue: []));
    _history.add({'sender': sender, 'msg': msg, 'time': DateTime.now().toIso8601String()});
    await box.put('chat', _history);
  }

  Future<void> _loadHistory() async {
    final box = Hive.box('memory');
    _history = List<Map>.from(box.get('chat', defaultValue: []));
  }

  Future<void> clearHistory() async {
    final box = Hive.box('memory');
    await box.put('chat', []);
    _history = [];
    notifyListeners();
    await speak('Sab kuch bhula diya');
  }
}
