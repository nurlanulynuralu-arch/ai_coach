import 'dart:math';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_constants.dart';
import '../core/constants/subject_content_catalog.dart';
import '../models/topic_knowledge.dart';
import '../models/topic_search_result.dart';
import 'study_material_parser.dart';

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
      final focusedTopic = StudyMaterialParser.normalizeTopicTitle(
        subject: subject,
        topic: topic,
      );
      try {
        final bestMatch = await _searchBestMatch('$subject $focusedTopic').timeout(
          const Duration(seconds: 8),
        );
        if (bestMatch == null) {
          knowledge[topic] = _fallbackKnowledge(subject: subject, topic: focusedTopic);
          continue;
        }

        final summary = await _fetchSummary(bestMatch, focusedTopic).timeout(
          const Duration(seconds: 8),
        );
        if (summary != null) {
          knowledge[topic] = summary;
        } else {
          knowledge[topic] = _fallbackKnowledge(subject: subject, topic: focusedTopic);
        }
      } catch (_) {
        knowledge[topic] = _fallbackKnowledge(subject: subject, topic: focusedTopic);
      }
    }

    return knowledge;
  }

  Future<List<TopicSearchResult>> searchTopicResults({
    required String subject,
    required String topic,
    int limit = 4,
  }) async {
    final focusedTopic = StudyMaterialParser.normalizeTopicTitle(
      subject: subject,
      topic: topic,
    );
    final results = await _searchWikipediaResults(
      query: '$subject $focusedTopic',
      maxResults: max(limit * 2, limit),
    );
    if (results.isEmpty) {
      return <TopicSearchResult>[
        _fallbackSearchResult(
          subject: subject,
          topic: focusedTopic,
        ),
      ];
    }

    final candidates = await Future.wait(
      results.take(max(limit * 2, limit)).toList().asMap().entries.map((entry) async {
        final rawResult = entry.value;
        final pageTitle = rawResult['title'] as String? ?? focusedTopic;
        final summary = await _fetchSummary(pageTitle, focusedTopic).timeout(
          const Duration(seconds: 8),
        );
        final snippet = _cleanSnippet(rawResult['snippet'] as String? ?? '');
        final displaySummary = summary?.summary ?? snippet;

        return TopicSearchResult(
          topic: focusedTopic,
          title: pageTitle,
          summary: displaySummary.isEmpty
              ? SubjectContentCatalog.fallbackSummaryFor(
                  subject: subject,
                  topic: focusedTopic,
                )
              : _trimSummary(displaySummary),
          sourceUrl: summary?.sourceUrl ??
              'https://en.wikipedia.org/wiki/${Uri.encodeComponent(pageTitle.replaceAll(' ', '_'))}',
          sourceLabel: 'Wikipedia',
          relevanceScore: _relevanceScore(
            subject: subject,
            topic: focusedTopic,
            title: pageTitle,
            snippet: snippet,
            index: entry.key,
          ),
          description: summary?.description,
        );
      }),
    );

    candidates.sort((first, second) => second.relevanceScore.compareTo(first.relevanceScore));
    return candidates.take(limit).toList();
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

  Future<List<dynamic>> _searchWikipediaResults({
    required String query,
    required int maxResults,
  }) async {
    final uri = Uri.parse(
      'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeQueryComponent(query)}&format=json&utf8=1&srlimit=$maxResults',
    );

    final data = await _getJson(uri);
    return data['query']?['search'] as List<dynamic>? ?? const <dynamic>[];
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

  String _cleanSnippet(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', '\'')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _relevanceScore({
    required String subject,
    required String topic,
    required String title,
    required String snippet,
    required int index,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerSnippet = snippet.toLowerCase();
    final lowerTopic = topic.toLowerCase();
    final lowerSubject = subject.toLowerCase();
    var score = 100 - (index * 8);

    if (lowerTitle == lowerTopic) {
      score += 40;
    } else if (lowerTitle.contains(lowerTopic)) {
      score += 24;
    }

    if (lowerSnippet.contains(lowerTopic)) {
      score += 14;
    }
    if (lowerTitle.contains(lowerSubject) || lowerSnippet.contains(lowerSubject)) {
      score += 8;
    }

    final topicKeywords = lowerTopic
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2)
        .toList();
    for (final keyword in topicKeywords) {
      if (lowerTitle.contains(keyword)) {
        score += 5;
      } else if (lowerSnippet.contains(keyword)) {
        score += 2;
      }
    }

    return score;
  }

  TopicKnowledge _fallbackKnowledge({
    required String subject,
    required String topic,
  }) {
    return TopicKnowledge(
      topic: topic,
      pageTitle: '$subject study guide',
      summary: SubjectContentCatalog.fallbackSummaryFor(
        subject: subject,
        topic: topic,
      ),
      sourceUrl: '',
      description: 'Built-in ${subject.toLowerCase()} guide',
    );
  }

  TopicSearchResult _fallbackSearchResult({
    required String subject,
    required String topic,
  }) {
    return TopicSearchResult(
      topic: topic,
      title: '$topic study guide',
      summary: SubjectContentCatalog.fallbackSummaryFor(
        subject: subject,
        topic: topic,
      ),
      sourceUrl: '',
      sourceLabel: 'Built-in guide',
      relevanceScore: 0,
      description: 'No internet source matched exactly',
      isFallback: true,
    );
  }
}
