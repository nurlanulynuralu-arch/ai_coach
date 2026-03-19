import 'package:flutter_test/flutter_test.dart';

import 'package:ai_study_coach/models/topic_search_result.dart';

void main() {
  const results = [
    TopicSearchResult(
      topic: 'Thermodynamics',
      title: 'Thermodynamics',
      summary: 'A longer explanation of heat, energy transfer, and systems.',
      sourceUrl: 'https://example.com/thermodynamics',
      sourceLabel: 'Wikipedia',
      relevanceScore: 160,
    ),
    TopicSearchResult(
      topic: 'Thermodynamics',
      title: 'Entropy',
      summary: 'Short summary.',
      sourceUrl: 'https://example.com/entropy',
      sourceLabel: 'Wikipedia',
      relevanceScore: 120,
    ),
    TopicSearchResult(
      topic: 'Thermodynamics',
      title: 'Heat engine',
      summary: 'Medium sized explanation.',
      sourceUrl: 'https://example.com/heat-engine',
      sourceLabel: 'Wikipedia',
      relevanceScore: 140,
    ),
  ];

  test('sorts topic search results by best match score', () {
    final sorted = sortTopicSearchResults(
      results,
      TopicSearchSortMode.bestMatch,
    );

    expect(sorted.first.title, 'Thermodynamics');
    expect(sorted.last.title, 'Entropy');
  });

  test('sorts topic search results alphabetically', () {
    final sorted = sortTopicSearchResults(
      results,
      TopicSearchSortMode.alphabetical,
    );

    expect(sorted.map((item) => item.title).toList(), [
      'Entropy',
      'Heat engine',
      'Thermodynamics',
    ]);
  });

  test('sorts topic search results by shortest summary first', () {
    final sorted = sortTopicSearchResults(
      results,
      TopicSearchSortMode.shortestSummary,
    );

    expect(sorted.first.title, 'Entropy');
  });
}
