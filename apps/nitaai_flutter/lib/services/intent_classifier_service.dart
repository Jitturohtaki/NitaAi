
import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum IntentCategory {
  grocery,
  food,
  transport,
  unknown;

  static IntentCategory fromString(String? value) {
    switch (value) {
      case 'grocery':
        return IntentCategory.grocery;
      case 'food':
        return IntentCategory.food;
      case 'transport':
        return IntentCategory.transport;
      default:
        return IntentCategory.unknown;
    }
  }
}

class IntentResult {
  IntentResult({
    required this.category,
    required this.confidence,
    this.rawModelText,
  });

  final IntentCategory category;
  final double confidence;
  final String? rawModelText;
}

class GeminiIntentClassifier {
  GeminiIntentClassifier() {
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    if (_apiKey == null || _apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('GEMINI_API_KEY not configured correctly in .env file');
    }
  }

  late final String? _apiKey;

  Future<IntentResult> classify(String userText) async {
    userText = userText.trim();
    if (userText.isEmpty) {
      return IntentResult(category: IntentCategory.unknown, confidence: 0.0);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.0,
          maxOutputTokens: 128,
        ),
      );

      final prompt = _buildPrompt(userText);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final modelText = response.text;
      if (modelText == null) {
        final (category, confidence) = _keywordIntentFallback(userText);
        return IntentResult(
          category: category,
          confidence: confidence,
          rawModelText: modelText,
        );
      }

      final (category, confidence) = _parseClassifierJson(modelText);
      return IntentResult(
        category: category ?? IntentCategory.unknown,
        confidence: confidence ?? 0.0,
        rawModelText: modelText,
      );
    } catch (e) {
      final (category, confidence) = _keywordIntentFallback(userText);
      return IntentResult(category: category, confidence: confidence);
    }
  }

  String _buildPrompt(String userText) {
    return '''
Classify the user's intent into ONE category.
Allowed categories: grocery, food, transport.
If none apply, use unknown.

Return ONLY valid JSON (no markdown, no extra keys):
{"category":"grocery|food|transport|unknown","confidence":0.0}

User message: $userText
''';
  }

  (IntentCategory?, double?) _parseClassifierJson(String modelText) {
    try {
      final jsonStartIndex = modelText.indexOf('{');
      final jsonEndIndex = modelText.lastIndexOf('}');
      if (jsonStartIndex == -1 || jsonEndIndex == -1) {
        return (null, null);
      }

      final jsonString = modelText.substring(jsonStartIndex, jsonEndIndex + 1);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final category = IntentCategory.fromString(json['category'] as String?);
      final confidence = json['confidence'] as double?;

      return (category, confidence);
    } catch (e) {
      return (null, null);
    }
  }

  (IntentCategory, double) _keywordIntentFallback(String userText) {
    final t = userText.toLowerCase();

    final grocery = [
      'grocery',
      'groceries',
      'supermarket',
      'mart',
      'vegetables',
      'fruits',
      'milk',
      'eggs',
      'bread',
      'rice',
      'dal',
      'atta',
      'flour',
      'soap',
      'detergent',
      'toothpaste',
      'shopping list',
    ];
    final food = [
      'food',
      'eat',
      'dinner',
      'lunch',
      'breakfast',
      'snack',
      'restaurant',
      'cafe',
      'pizza',
      'burger',
      'biryani',
      'order',
      'zomato',
      'swiggy',
      'delivery',
    ];
    final transport = [
      'transport',
      'cab',
      'taxi',
      'uber',
      'ola',
      'auto',
      'rickshaw',
      'bus',
      'metro',
      'train',
      'flight',
      'ticket',
      'commute',
      'ride',
      'drop',
      'pickup',
    ];

    final scores = <IntentCategory, int>{
      IntentCategory.grocery: 0,
      IntentCategory.food: 0,
      IntentCategory.transport: 0,
      IntentCategory.unknown: 0,
    };

    scores[IntentCategory.grocery] =
        grocery.where((k) => t.contains(k)).length;
    scores[IntentCategory.food] = food.where((k) => t.contains(k)).length;
    scores[IntentCategory.transport] =
        transport.where((k) => t.contains(k)).length;

    final best = scores.entries
        .where((e) => e.key != IntentCategory.unknown)
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final bestScore = scores[best]!;
    if (bestScore == 0) {
      return (IntentCategory.unknown, 0.2);
    }

    final confidence = min(0.95, 0.55 + (bestScore * 0.12));
    return (best, confidence);
  }
}
