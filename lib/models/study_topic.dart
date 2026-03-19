class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.title,
    required this.importance,
    this.referenceSummary,
    this.referenceTitle,
    this.referenceUrl,
  });

  final String id;
  final String title;
  final int importance;
  final String? referenceSummary;
  final String? referenceTitle;
  final String? referenceUrl;

  factory StudyTopic.fromMap(Map<String, dynamic> map) {
    return StudyTopic(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      importance: (map['importance'] as num?)?.toInt() ?? 1,
      referenceSummary: map['referenceSummary'] as String?,
      referenceTitle: map['referenceTitle'] as String?,
      referenceUrl: map['referenceUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'importance': importance,
      'referenceSummary': referenceSummary,
      'referenceTitle': referenceTitle,
      'referenceUrl': referenceUrl,
    };
  }

  StudyTopic copyWith({
    String? id,
    String? title,
    int? importance,
    String? referenceSummary,
    String? referenceTitle,
    String? referenceUrl,
  }) {
    return StudyTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      importance: importance ?? this.importance,
      referenceSummary: referenceSummary ?? this.referenceSummary,
      referenceTitle: referenceTitle ?? this.referenceTitle,
      referenceUrl: referenceUrl ?? this.referenceUrl,
    );
  }
}
