class TopicKnowledge {
  const TopicKnowledge({
    required this.topic,
    required this.pageTitle,
    required this.summary,
    required this.sourceUrl,
    this.description,
  });

  final String topic;
  final String pageTitle;
  final String summary;
  final String sourceUrl;
  final String? description;
}
