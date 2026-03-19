import 'package:flutter_test/flutter_test.dart';

import 'package:ai_study_coach/services/study_material_parser.dart';

void main() {
  test('extracts subject topics from pasted study materials', () {
    const material = '''
    Unit 1: Thermodynamics
    - Heat transfer and thermal equilibrium
    - Electric circuits
    Practice explaining units and equations.
    ''';

    final topics = StudyMaterialParser.extractTopics(
      subject: 'Physics',
      content: material,
      maxTopics: 6,
    );

    expect(topics.map((item) => item.toLowerCase()), contains('thermodynamics'));
    expect(topics.map((item) => item.toLowerCase()), contains('electric circuits'));
  });

  test('finds a relevant excerpt for the selected topic', () {
    const material = '''
    Thermodynamics explains how heat, temperature, and energy transfer behave in physical systems.
    Kinematics focuses on motion, velocity, and acceleration.
    ''';

    final excerpt = StudyMaterialParser.excerptForTopic(
      topic: 'Thermodynamics',
      content: material,
    );

    expect(excerpt, isNotNull);
    expect(excerpt!.toLowerCase(), contains('heat'));
    expect(excerpt.toLowerCase(), isNot(contains('photosynthesis')));
  });

  test('normalizes topic labels with subject prefixes', () {
    final topic = StudyMaterialParser.normalizeTopicTitle(
      subject: 'Physics',
      topic: 'Physics: Thermodynamics',
    );

    expect(topic, 'Thermodynamics');
  });
}
