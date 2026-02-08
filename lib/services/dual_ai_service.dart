import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

class DualAiService {
  // Gemini Setup
  late final GenerativeModel _geminiModel;

  DualAiService() {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: ApiKeys.geminiKey,
    );
  }

  /// Queries both Gemini and OpenAI for holistic Ayurvedic advice
  Future<String> getAyurvedicAdvice(String query) async {
    final String systemPrompt = 
        "You are an expert Ayurvedic Vaidya and Modern Health Consultant. "
        "Provide a concise, holistic answer combining ancient wisdom (Doshas, Herbs) and modern science. "
        "Focus on senior citizens. Keep it respectful, clear, and safe.";

    try {
      // Create futures for parallel execution
      final geminiFuture = _queryGemini(systemPrompt, query);
      final openAiFuture = _queryOpenAi(systemPrompt, query);

      // Wait for both results
      final results = await Future.wait([geminiFuture, openAiFuture]);
      
      final geminiResponse = results[0];
      final openAiResponse = results[1];

      return "🌿 **Ayurvedic Wisdom (Gemini)**:\n$geminiResponse\n\n"
             "🔬 **Modern Insight (OpenAI)**:\n$openAiResponse\n\n"
             "✨ **Holistic Verdict**: Both perspectives suggest focusing on balance and moderation. Please consult a doctor for severe symptoms.";

    } catch (e) {
      return "I apologize, but I'm having trouble connecting to the ancient wisdom archives right now. Error: $e";
    }
  }

  Future<String> _queryGemini(String systemPrompt, String query) async {
    try {
      final content = [Content.text("$systemPrompt\n\nUser Question: $query")];
      final response = await _geminiModel.generateContent(content);
      return response.text ?? "No advice available from Gemini.";
    } catch (e) {
      return "Gemini is meditating. (Error: $e)";
    }
  }

  Future<String> _queryOpenAi(String systemPrompt, String query) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // or gpt-3.5-turbo if cost is concern
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': query}
          ],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString();
      } else if (response.statusCode == 429) {
        return "OpenAI is currently overloaded (429 Rate Limit). Please try again in 30 seconds.";
      } else {
        return "OpenAI is unreachable (${response.statusCode}). Please check your API key credits.";
      }
    } catch (e) {
      return "OpenAI is silent. (Error: $e)";
    }
  }
}
