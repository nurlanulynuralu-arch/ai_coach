import 'dart:convert';
import 'dart:io';

import '../core/constants/app_constants.dart';
import '../models/topic_knowledge.dart';

class TopicKnowledgeService {
  TopicKnowledgeService({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 8);
  }

  final HttpClient _client;

  Future<Map<String, TopicKnowledge>> fetchTopicKnowledge({
    required String subject,
    required List<String> topics,
  }) async {
    final knowledge = <String, TopicKnowledge>{};

    for (final topic in topics) {
      try {
        final bestMatch = await _searchBestMatch('$subject $topic').timeout(
          const Duration(seconds: 8),
        );
        if (bestMatch == null) {
          continue;
        }

        final summary = await _fetchSummary(bestMatch, topic).timeout(
          const Duration(seconds: 8),
        );
        if (summary != null) {
          knowledge[topic] = summary;
        }
      } catch (_) {
        continue;
      }
    }

    return knowledge;
  }

  Future<String?> _searchBestMatch(String query) async {
    final uri = Uri.parse(
      'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeQueryComponent(query)}&format=json&utf8=1&srlimit=1',
    );

    final data = await _getJson(uri);
    final searchResults = data['query']?['search'] as List<dynamic>? ?? const <dynamic>[];
    if (searchResults.isEmpty) {
      return null;
    }

    return searchResults.first['title'] as String?;
  }

  Future<TopicKnowledge?> _fetchSummary(String pageTitle, String topic) async {
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(pageTitle)}',
    );
    final data = await _getJson(uri);
    final extract = (data['extract'] as String?)?.trim();
    if (extract == null || extract.isEmpty) {
      return null;
    }

    final sourceUrl = data['content_urls']?['desktop']?['page'] as String? ??
        'https://en.wikipedia.org/wiki/${Uri.encodeComponent(pageTitle.replaceAll(' ', '_'))}';

    return TopicKnowledge(
      topic: topic,
      pageTitle: data['title'] as String? ?? pageTitle,
      summary: _trimSummary(extract),
      sourceUrl: sourceUrl,
      description: (data['description'] as String?)?.trim(),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'AIStudyCoach/1.0 (${AppConstants.supportEmail})');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Request failed with status ${response.statusCode}', uri: uri);
    }

    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _trimSummary(String summary) {
    if (summary.length <= 260) {
      return summary;
    }

    final short = summary.substring(0, 257).trimRight();
    return '$short...';
  }
}
