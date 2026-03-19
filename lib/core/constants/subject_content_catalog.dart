import 'app_constants.dart';

class SubjectContentCatalog {
  static List<String> topicPromptsFor(String subject) {
    return List<String>.from(
      _topicPrompts[_normalize(subject)] ?? AppConstants.emptyTopicPrompts,
    );
  }

  static List<String> weakAreaPromptsFor(String subject) {
    return List<String>.from(
      _weakAreaPrompts[_normalize(subject)] ?? AppConstants.weakAreaPrompts,
    );
  }

  static String topicHintFor(String subject) {
    switch (_normalize(subject)) {
      case 'physics':
        return 'e.g. Newton\'s laws, kinematics, electric circuits';
      case 'mathematics':
        return 'e.g. Quadratics, derivatives, probability';
      case 'chemistry':
        return 'e.g. Chemical bonding, stoichiometry, equilibrium';
      case 'history':
        return 'e.g. World War I causes, Cold War, source analysis';
      case 'computer science':
        return 'e.g. Algorithms, data structures, databases';
      case 'english':
        return 'e.g. Essay structure, grammar, text analysis';
      case 'biology':
        return 'e.g. Photosynthesis, genetics, homeostasis';
      default:
        return 'e.g. Core concepts, exam themes, difficult chapters';
    }
  }

  static String studyDescriptionFor({
    required String subject,
    required String topic,
    required bool simpleLanguage,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return simpleLanguage
            ? 'Break down $topic into the main rule, the quantities involved, and one worked example with units.'
            : 'Study $topic by naming the physical quantities, matching the correct law or equation, and explaining when that model applies.';
      case 'mathematics':
        return simpleLanguage
            ? 'Write the method for $topic step by step and solve one simple example without skipping the working.'
            : 'Study $topic as a process: definition, rule, worked example, and the mistake that usually causes the wrong sign, value, or formula.';
      case 'chemistry':
        return simpleLanguage
            ? 'Learn what happens in $topic, the particles involved, and one clear chemical example.'
            : 'Study $topic by linking particle behaviour, equations, observations, and the conditions that change the reaction or trend.';
      case 'history':
        return simpleLanguage
            ? 'Explain $topic as a short story with key events, causes, and results in the right order.'
            : 'Study $topic through chronology, causes, consequences, and significance, then link it to one piece of supporting evidence or source detail.';
      case 'computer science':
        return simpleLanguage
            ? 'Explain what $topic does, where it is used, and one simple example of input and output.'
            : 'Study $topic by defining the concept, showing how it works step by step, and explaining the trade-off, limitation, or real use case.';
      case 'english':
        return simpleLanguage
            ? 'Study $topic with one rule, one model sentence, and one common mistake to avoid.'
            : 'Study $topic by connecting language rule, text evidence, and exam-style structure so you can explain both what is correct and why.';
      case 'biology':
      default:
        return simpleLanguage
            ? 'Explain $topic in simple biological terms, then connect it to one structure, process, or function.'
            : 'Study $topic by linking structure, process, purpose, and one real biological example that could appear in an exam answer.';
    }
  }

  static String practiceDescriptionFor({
    required String subject,
    required String topic,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return 'Solve 2-3 physics questions on $topic, list the known values, choose the right equation, then justify the final unit and direction.';
      case 'mathematics':
        return 'Solve 2-3 maths questions on $topic, show every transformation clearly, then check the final answer by substitution, graph, or estimation.';
      case 'chemistry':
        return 'Practice 2-3 chemistry questions on $topic and explain the reaction, trend, or calculation instead of writing only the final answer.';
      case 'history':
        return 'Answer 2 history questions on $topic using cause, consequence, evidence, and significance instead of only retelling events.';
      case 'computer science':
        return 'Complete 2-3 questions on $topic and explain the logic, sequence, or trade-off behind the solution, not just the final output.';
      case 'english':
        return 'Practice 2-3 English questions on $topic and justify each answer with a grammar rule, text clue, or sentence structure.';
      case 'biology':
      default:
        return 'Complete 2-3 practice questions on $topic, then explain the process, function, or relationship behind each correct answer.';
    }
  }

  static String flashcardDescriptionFor({
    required String subject,
    required String topic,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return 'Review the flashcards for $topic, say the equation trigger aloud, and explain what each variable and unit means.';
      case 'mathematics':
        return 'Review the flashcards for $topic, state the rule aloud, and recall the next algebraic or calculus step before flipping the card.';
      case 'chemistry':
        return 'Review the flashcards for $topic, name the particles or terms aloud, and connect them to one reaction, trend, or formula.';
      case 'history':
        return 'Review the flashcards for $topic, say the dates, causes, and consequences aloud, and connect them to one supporting example.';
      case 'computer science':
        return 'Review the flashcards for $topic, describe the logic in your own words, and connect each card to one real coding or systems example.';
      case 'english':
        return 'Review the flashcards for $topic, say the rule or vocabulary aloud, and use it in one sentence before flipping the card.';
      case 'biology':
      default:
        return 'Review the flashcards for $topic, say the definition aloud, and connect it to one biological process, structure, or exam clue.';
    }
  }

  static String reviewDescriptionFor({
    required String subject,
    required String topic,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return 'Return to $topic, reteach the idea in your own words, solve one more question, and check whether your units and reasoning are now consistent.';
      case 'mathematics':
        return 'Return to $topic, redo one worked solution from memory, and check whether your method stays correct from the first step to the last.';
      case 'chemistry':
        return 'Return to $topic, explain the concept again from memory, and compare particle-level reasoning with the final equation or calculation.';
      case 'history':
        return 'Return to $topic, explain the chain of events again from memory, and strengthen your answer with one more reason, source, or consequence.';
      case 'computer science':
        return 'Return to $topic, explain the mechanism from memory, and test whether you can describe both how it works and why it is used.';
      case 'english':
        return 'Return to $topic, rewrite one answer or sentence from memory, and check the rule, evidence, and wording for accuracy.';
      case 'biology':
      default:
        return 'Return to $topic, reteach it in your own words, and verify that you can connect the process to its purpose and one real example.';
    }
  }

  static String mixedRevisionDescriptionFor({
    required String subject,
    required List<String> focusTopics,
  }) {
    final joinedTopics = focusTopics.join(', ');

    switch (_normalize(subject)) {
      case 'physics':
        return 'Review $joinedTopics in one session, compare the equations or principles, and finish with a mixed set of concept and calculation checks.';
      case 'mathematics':
        return 'Review $joinedTopics in one session, compare the methods side by side, and finish with a mixed set of problems from easy to exam-style.';
      case 'chemistry':
        return 'Review $joinedTopics in one session, connect the processes and equations, and finish with mixed questions on trends, reactions, and calculations.';
      case 'history':
        return 'Review $joinedTopics in one session, compare causes and consequences across the topics, and finish with one short structured paragraph from memory.';
      case 'computer science':
        return 'Review $joinedTopics in one session, compare the logic and trade-offs, and finish with a mini quiz on definitions, sequence, and application.';
      case 'english':
        return 'Review $joinedTopics in one session, compare the language rules or text features, and finish with one short writing or comprehension check.';
      case 'biology':
      default:
        return 'Review $joinedTopics in one session, connect structures, processes, and functions, and finish with a mixed self-test before moving on.';
    }
  }

  static String explanationFor({
    required String subject,
    required String topic,
    required bool simpleLanguage,
    required String examType,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return simpleLanguage
            ? '$topic in physics is about the relationship between quantities, units, and the law that connects them. Learn what changes, what stays constant, and when to use the formula.'
            : '$topic in physics should be revised through variables, equations, units, graphs, and assumptions. In a ${examType.toLowerCase()}, explain the physical meaning, justify the model you use, and show why the final unit or direction makes sense.';
      case 'mathematics':
        return simpleLanguage
            ? '$topic in mathematics is a method you should follow step by step. Learn the rule, apply it to one example, and check where mistakes usually happen.'
            : '$topic in mathematics should be understood as a method, not memorised as a final answer. In a ${examType.toLowerCase()}, define the idea, apply the correct rule, and explain the reasoning in each step.';
      case 'chemistry':
        return simpleLanguage
            ? '$topic in chemistry is easier when you connect what the particles do, what changes in the equation, and what you would observe.'
            : '$topic in chemistry should be revised through particle behaviour, equations, trends, and conditions. In a ${examType.toLowerCase()}, explain the process clearly and connect it to evidence or calculation.';
      case 'history':
        return simpleLanguage
            ? '$topic in history is best learned as a sequence of causes, events, and results. Keep the timeline clear and explain why the event mattered.'
            : '$topic in history should be revised through chronology, causation, consequence, significance, and evidence. In a ${examType.toLowerCase()}, avoid retelling only facts and explain why the event or development mattered.';
      case 'computer science':
        return simpleLanguage
            ? '$topic in computer science is easier when you explain what it does, how it works step by step, and where it is used.'
            : '$topic in computer science should be revised through definition, mechanism, example, and trade-off. In a ${examType.toLowerCase()}, explain the logic, not only the final output or term.';
      case 'english':
        return simpleLanguage
            ? '$topic in English should be revised through one clear rule, one correct example, and one common mistake to avoid.'
            : '$topic in English should be revised through language rule, text evidence, and exam structure. In a ${examType.toLowerCase()}, explain why an answer is correct and support it with a short example or quotation.';
      case 'biology':
      default:
        return simpleLanguage
            ? '$topic in biology is easier when you connect the structure, the process, and the job it does in a living system.'
            : '$topic in biology should be revised through structure, process, function, and interaction. In a ${examType.toLowerCase()}, explain how the system works and why the process matters in living organisms.';
    }
  }

  static String coachingLineFor({
    required String subject,
    required String topic,
    required bool simpleLanguage,
    required String examType,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return simpleLanguage
            ? 'Focus on symbols, units, and one worked example.'
            : 'Focus on variable meaning, equation choice, assumptions, and the unit or graph that proves your answer is reasonable.';
      case 'mathematics':
        return simpleLanguage
            ? 'Focus on the rule and the order of steps.'
            : 'Focus on method, justification, and the exact step where students usually lose accuracy.';
      case 'chemistry':
        return simpleLanguage
            ? 'Focus on particles, equations, and one observation.'
            : 'Focus on particle-level reasoning, chemical equations, conditions, and the observation or calculation an examiner expects.';
      case 'history':
        return simpleLanguage
            ? 'Focus on timeline, cause, and result.'
            : 'Focus on chronology, causation, evidence, and significance so your ${examType.toLowerCase()} answer sounds analytical, not descriptive.';
      case 'computer science':
        return simpleLanguage
            ? 'Focus on what happens first, next, and why.'
            : 'Focus on logic, sequence, use case, and the limitation or trade-off connected to the concept.';
      case 'english':
        return simpleLanguage
            ? 'Focus on one rule, one example, and one error to avoid.'
            : 'Focus on language rule, text evidence, and how to justify the answer clearly in an exam response.';
      case 'biology':
      default:
        return simpleLanguage
            ? 'Focus on the process and what it does in the body or cell.'
            : 'Focus on the mechanism, the function, and the link between this topic and the wider biological system.';
    }
  }

  static String exampleFor({
    required String subject,
    required String topic,
  }) {
    switch (_normalize(subject)) {
      case 'physics':
        return 'Example: pick one $topic question, write the known quantities, choose the formula, solve it, and check whether the unit and direction make sense.';
      case 'mathematics':
        return 'Example: solve one $topic problem from start to finish, explain every step aloud, and then verify the result with a second method if possible.';
      case 'chemistry':
        return 'Example: explain one $topic reaction, trend, or calculation and state what is happening at particle level as well as in the equation.';
      case 'history':
        return 'Example: write a short paragraph on $topic using one cause, one consequence, and one piece of supporting evidence.';
      case 'computer science':
        return 'Example: explain how $topic works step by step, then connect it to one algorithm, program feature, or real system.';
      case 'english':
        return 'Example: use $topic in one sentence or paragraph, then explain the grammar rule, text feature, or evidence that makes it correct.';
      case 'biology':
      default:
        return 'Example: explain $topic in simple words and connect it to one structure, one process step, and one function in a living system.';
    }
  }

  static String fallbackSummaryFor({
    required String subject,
    required String topic,
  }) {
    return explanationFor(
      subject: subject,
      topic: topic,
      simpleLanguage: false,
      examType: 'exam',
    );
  }

  static String _normalize(String subject) => subject.trim().toLowerCase();

  static const Map<String, List<String>> _topicPrompts = {
    'biology': [
      'Cell structure and organelles',
      'Photosynthesis and respiration',
      'Genetics and inheritance',
      'Enzymes and metabolism',
      'Homeostasis and feedback',
      'Ecology and ecosystems',
      'DNA replication and protein synthesis',
      'Nervous and endocrine systems',
    ],
    'mathematics': [
      'Algebraic manipulation',
      'Functions and graphs',
      'Quadratics',
      'Derivatives',
      'Integrals',
      'Probability and statistics',
      'Trigonometry',
      'Sequences and series',
    ],
    'physics': [
      'Kinematics and motion',
      'Forces and Newton\'s laws',
      'Work, energy, and power',
      'Momentum and collisions',
      'Electric circuits',
      'Waves and optics',
      'Thermal physics',
      'Electromagnetism',
    ],
    'chemistry': [
      'Atomic structure and periodic trends',
      'Chemical bonding',
      'Stoichiometry',
      'Acids, bases, and pH',
      'Rates of reaction',
      'Organic chemistry basics',
      'Chemical equilibrium',
      'Redox and electrochemistry',
    ],
    'history': [
      'Causes of World War I',
      'Industrial Revolution',
      'Cold War',
      'Nationalism and empire',
      'Source analysis',
      'Cause and consequence essays',
      'Revolutions and reform movements',
      'Interwar period and World War II',
    ],
    'computer science': [
      'Algorithms and flowcharts',
      'Data structures',
      'Programming fundamentals',
      'Boolean logic',
      'Networks and cybersecurity',
      'Databases and SQL',
      'Object-oriented programming',
      'Recursion and problem decomposition',
    ],
    'english': [
      'Reading comprehension',
      'Essay structure',
      'Grammar and sentence control',
      'Vocabulary in context',
      'Text analysis',
      'Argument and evidence',
      'Literary devices',
      'Speaking and discussion prompts',
    ],
  };

  static const Map<String, List<String>> _weakAreaPrompts = {
    'biology': [
      'Process steps',
      'Definitions',
      'Diagrams',
      'Comparisons',
      'Scientific vocabulary',
      'Cause and effect',
    ],
    'mathematics': [
      'Problem solving',
      'Algebra mistakes',
      'Formula recall',
      'Graph interpretation',
      'Units and notation',
      'Multi-step solutions',
    ],
    'physics': [
      'Formula selection',
      'Units',
      'Graph interpretation',
      'Free-body diagrams',
      'Word problems',
      'Explaining reasoning',
    ],
    'chemistry': [
      'Balancing equations',
      'Mole calculations',
      'Periodic trends',
      'Acid-base reasoning',
      'Organic reactions',
      'Particle explanations',
    ],
    'history': [
      'Chronology',
      'Source analysis',
      'Essay structure',
      'Evidence recall',
      'Cause vs consequence',
      'Comparative arguments',
    ],
    'computer science': [
      'Tracing code',
      'Algorithm design',
      'Complexity',
      'Database queries',
      'Networking terms',
      'Debugging logic',
    ],
    'english': [
      'Grammar',
      'Vocabulary',
      'Text evidence',
      'Essay structure',
      'Time management',
      'Explaining quotations',
    ],
  };
}
