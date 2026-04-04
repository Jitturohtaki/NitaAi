import 'package:flutter_test/flutter_test.dart';
import 'package:nitaai_flutter/services/intent_classifier_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    // Load a dummy env for testing
    dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=TEST_KEY
''');
  });

  test('GeminiIntentClassifier can be created', () {
    final classifier = GeminiIntentClassifier();
    expect(classifier, isNotNull);
  });

  test('Classifier should return transport for a transport-related query',
      () async {
    final classifier = GeminiIntentClassifier();
    final result = await classifier.classify('Book me a cab to the airport');
    expect(result.category, IntentCategory.transport);
  });

  test('Classifier should use keyword fallback for a known keyword', () async {
    final classifier = GeminiIntentClassifier();
    // This test will fail if run with a real API key, as it's testing the fallback
    final result = await classifier.classify('I need to buy some bread');
    expect(result.category, IntentCategory.grocery);
  });
}
