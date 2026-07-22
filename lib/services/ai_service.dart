import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';

class AiSearchResult {
  final String textResponse;
  final List<String> matchedVendorIds;
  final String? suggestedCorrection;

  AiSearchResult({
    required this.textResponse,
    this.matchedVendorIds = const [],
    this.suggestedCorrection,
  });
}

class AiService {
  static String get _apiKey =>
      dotenv.env['GROQ_API_KEY'] ?? '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';
  static String get _model => dotenv.env['GROQ_MODEL'] ?? 'qwen/qwen3.6-27b';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Clean output by removing any <think>...</think> reasoning blocks
  static String _cleanResponse(String text) {
    var cleaned = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    if (cleaned.startsWith('<think>')) {
      final closeIdx = cleaned.indexOf('</think>');
      if (closeIdx != -1) {
        cleaned = cleaned.substring(closeIdx + 8).trim();
      }
    }
    return cleaned;
  }

  /// Perform AI-powered natural language and fuzzy search against kitchens and their menus
  static Future<AiSearchResult> searchAssistant({
    required String query,
    required List<VendorModel> vendors,
    Map<String, List<MenuItemModel>> vendorMenus = const {},
  }) async {
    try {
      final vendorContextList = vendors.map((v) {
        final menu = vendorMenus[v.id] ?? [];
        return {
          'id': v.id,
          'name': v.businessName,
          'description': v.description ?? '',
          'isOpenNow': v.isOpenNow,
          'menuItems': menu.map((m) => {
                'name': m.name,
                'description': m.description ?? '',
                'price': m.price,
                'category': m.category ?? '',
              }).toList(),
        };
      }).toList();

      final systemPrompt = '''
You are Plokitch AI Assistant, an intelligent culinary search assistant for the Plokitch food app in Gombe, Nigeria.
Your job is to assist customers searching for kitchens, dishes, menu items, or asking natural language queries (e.g., "closest open kitchen with meatpie", or misspelled kitchen names like "sudo kitchn").

You MUST return a JSON object ONLY with the following exact keys:
{
  "textResponse": "A clear, concise, friendly response to the customer (1-3 sentences). Highlight matched kitchens, menu items, or correct any misspelled kitchen names.",
  "matchedVendorIds": ["list of matching vendor IDs"],
  "suggestedCorrection": "Corrected name if user misspelled a kitchen name, else null"
}

Available Kitchens & Menus Context:
${json.encode(vendorContextList)}
''';

      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': query},
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final choices = body['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']['content'] as String? ?? '';
          final cleaned = _cleanResponse(content);
          
          try {
            final parsed = json.decode(cleaned) as Map<String, dynamic>;
            final matchedIds = (parsed['matchedVendorIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
            return AiSearchResult(
              textResponse: parsed['textResponse'] as String? ?? 'Here are the closest recommendations based on your search.',
              matchedVendorIds: matchedIds,
              suggestedCorrection: parsed['suggestedCorrection'] as String?,
            );
          } catch (_) {
            return AiSearchResult(textResponse: cleaned);
          }
        }
      }

      // Fallback if API fails or status != 200
      return _generateFallbackResult(query, vendors, vendorMenus);
    } catch (_) {
      return _generateFallbackResult(query, vendors, vendorMenus);
    }
  }

  static AiSearchResult _generateFallbackResult(
    String query,
    List<VendorModel> vendors,
    Map<String, List<MenuItemModel>> vendorMenus,
  ) {
    final q = query.toLowerCase();
    final matchedIds = <String>[];
    String? correction;

    for (final v in vendors) {
      if (v.businessName.toLowerCase().contains(q) || (v.description ?? '').toLowerCase().contains(q)) {
        matchedIds.add(v.id);
      } else {
        final name = v.businessName.toLowerCase();
        if (_isSimilar(q, name)) {
          matchedIds.add(v.id);
          correction = v.businessName;
        }
      }
    }

    String msg;
    if (matchedIds.isNotEmpty) {
      if (correction != null) {
        msg = 'Did you mean "$correction"? We found matching kitchens for your search.';
      } else {
        msg = 'Found ${matchedIds.length} kitchen(s) matching your request.';
      }
    } else {
      msg = 'No exact kitchen matches found for "$query". Try searching for popular dishes like Jollof or Meatpie!';
    }

    return AiSearchResult(
      textResponse: msg,
      matchedVendorIds: matchedIds,
      suggestedCorrection: correction,
    );
  }

  static bool _isSimilar(String s1, String s2) {
    if (s1.length < 3 || s2.length < 3) return false;
    final prefix1 = s1.substring(0, (s1.length * 0.6).round());
    return s2.contains(prefix1);
  }
}
