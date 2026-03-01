import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

class ChatQA {
  final String question;
  final String answer;
  final String category;

  // Optional localized fields (kept optional for backward compatibility)
  final String? questionTa;
  final String? answerTa;
  final String? categoryTa;

  ChatQA({
    required this.question,
    required this.answer,
    required this.category,
    this.questionTa,
    this.answerTa,
    this.categoryTa,
  });

  factory ChatQA.fromJson(Map<String, dynamic> j) => ChatQA(
        question: (j['question'] ?? '').toString(),
        answer: (j['answer'] ?? '').toString(),
        category: (j['category'] ?? 'General').toString(),
        questionTa: j['question_ta']?.toString(),
        answerTa: j['answer_ta']?.toString(),
        categoryTa: j['category_ta']?.toString(),
      );

  /// Returns best text for current language.
  /// If Tamil requested but missing, falls back to English.
  String questionForLang(String langCode) {
    if (langCode == 'ta') return (questionTa?.trim().isNotEmpty ?? false) ? questionTa! : question;
    return question;
  }

  String answerForLang(String langCode) {
    if (langCode == 'ta') return (answerTa?.trim().isNotEmpty ?? false) ? answerTa! : answer;
    return answer;
  }

  String categoryForLang(String langCode) {
    if (langCode == 'ta') return (categoryTa?.trim().isNotEmpty ?? false) ? categoryTa! : category;
    return category;
  }
}

class WasteChatbotEngine {
  static bool _loaded = false;
  static final List<ChatQA> _items = [];

  // Stores current language for matching + quick questions.
  // Default en; set from load(context: ...)
  static String _lang = 'en';

  /// ✅ Update: allow passing context to detect current app language.
  /// Backward compatible: you can still call WasteChatbotEngine.load() without params.
  static Future<void> load({BuildContext? context}) async {
    if (_loaded) return;

    if (context != null) {
      _lang = Localizations.localeOf(context).languageCode;
    } else {
      _lang = 'en';
    }

    final raw = await rootBundle.loadString('assets/waste_chatbot_qa.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = (data['items'] as List).cast<Map<String, dynamic>>();

    _items
      ..clear()
      ..addAll(list.map(ChatQA.fromJson));

    _loaded = true;
  }

  /// Optional: call this whenever language changes (like your AppLang switch)
  static void setLanguage(String langCode) {
    _lang = langCode;
  }

  static bool get isLoaded => _loaded;

  static List<ChatQA> get items => List.unmodifiable(_items);

  /// Normalizer that supports English + Tamil.
  /// Keeps Tamil letters (U+0B80–U+0BFF) and Latin letters/digits.
  static String _norm(String s) {
    final lower = s.toLowerCase();

    // Keep: a-z, 0-9, whitespace, and Tamil unicode block \u0B80-\u0BFF
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // simple token overlap scorer
  static ChatQA? bestMatch(String query) {
    if (!_loaded || _items.isEmpty) return null;
    final q = _norm(query);
    if (q.isEmpty) return null;

    final qTokens = q.split(' ').toSet();
    ChatQA? best;
    int bestScore = 0;

    for (final item in _items) {
      // ✅ Match against language-appropriate question
      final t = _norm(item.questionForLang(_lang));
      if (t.isEmpty) continue;

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

  // “Quick questions”
  static List<ChatQA> quickQuestions({int limit = 10}) {
    if (!_loaded) return [];
    return _items.take(limit).toList();
  }

  /// Helpers for UI (so your AssistantOverlay can show correct language easily)
  static String get currentLanguage => _lang;

  static String questionText(ChatQA qa) => qa.questionForLang(_lang);
  static String answerText(ChatQA qa) => qa.answerForLang(_lang);
  static String categoryText(ChatQA qa) => qa.categoryForLang(_lang);
}