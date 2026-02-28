import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ChatQA {
  final String question;
  final String answer;
  final String category;
  ChatQA({required this.question, required this.answer, required this.category});

  factory ChatQA.fromJson(Map<String, dynamic> j) => ChatQA(
    question: (j['question'] ?? '').toString(),
    answer: (j['answer'] ?? '').toString(),
    category: (j['category'] ?? 'General').toString(),
  );
}

class WasteChatbotEngine {
  static bool _loaded = false;
  static final List<ChatQA> _items = [];

  static Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/waste_chatbot_qa.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = (data['items'] as List).cast<Map<String, dynamic>>();
    _items
      ..clear()
      ..addAll(list.map(ChatQA.fromJson));
    _loaded = true;
  }

  static bool get isLoaded => _loaded;

  static List<ChatQA> get items => List.unmodifiable(_items);

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // simple token overlap scorer
  static ChatQA? bestMatch(String query) {
    if (!_loaded || _items.isEmpty) return null;
    final q = _norm(query);
    if (q.isEmpty) return null;

    final qTokens = q.split(' ').toSet();
    ChatQA? best;
    int bestScore = 0;

    for (final item in _items) {
      final t = _norm(item.question);
      final tTokens = t.split(' ').toSet();
      final score = qTokens.intersection(tTokens).length;
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    // if score too low -> treat as unknown
    if (bestScore < 2) return null;
    return best;
  }

  // “Quick questions” like Airtel Thanks
  static List<ChatQA> quickQuestions({int limit = 10}) {
    if (!_loaded) return [];
    return _items.take(limit).toList();
  }
}