class TopicSearchResult {
  const TopicSearchResult({
    required this.topic,
    required this.title,
    required this.summary,
    required this.sourceUrl,
    required this.sourceLabel,
    required this.relevanceScore,
    this.description,
    this.isFallback = false,
  });

  final String topic;
  final String title;
  final String summary;
  final String sourceUrl;
  final String sourceLabel;
  final int relevanceScore;
  final String? description;
  final bool isFallback;

  int get summaryLength => summary.trim().length;
}

enum TopicSearchSortMode {
  bestMatch,
  alphabetical,
  shortestSummary,
}

extension TopicSearchSortModeX on TopicSearchSortMode {
  String get label {
    switch (this) {
      case TopicSearchSortMode.bestMatch:
        return 'Best match';
      case TopicSearchSortMode.alphabetical:
        return 'A-Z';
      case TopicSearchSortMode.shortestSummary:
        return 'Shortest';
    }
  }
}

List<TopicSearchResult> sortTopicSearchResults(
  Iterable<TopicSearchResult> results,
  TopicSearchSortMode mode,
) {
  final items = List<TopicSearchResult>.from(results);

  switch (mode) {
    case TopicSearchSortMode.bestMatch:
      items.sort((first, second) {
        final scoreCompare = second.relevanceScore.compareTo(first.relevanceScore);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return first.title.compareTo(second.title);
      });
      break;
    case TopicSearchSortMode.alphabetical:
      items.sort((first, second) => first.title.compareTo(second.title));
      break;
    case TopicSearchSortMode.shortestSummary:
      items.sort((first, second) {
        final lengthCompare = first.summaryLength.compareTo(second.summaryLength);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return second.relevanceScore.compareTo(first.relevanceScore);
      });
      break;
  }

  return items;
}
