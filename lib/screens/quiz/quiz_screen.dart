import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_question.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final studyProvider = context.watch<StudyPlanProvider>();
    final questions = quizProvider.questions;
    final exam = studyProvider.activeExam;

    if (quizProvider.isLoading) {
      return const Scaffold(body: LoadingStateView());
    }

    if (questions.isEmpty) {
      return Scaffold(
        body: GradientBackground(
          child: SafeArea(
            child: EmptyStateView(
              title: 'No quiz ready',
              message: 'Generate a study plan first so the app can create quiz questions from your topics.',
              icon: Icons.quiz_outlined,
              actionLabel: 'Open exam setup',
              onAction: () => context.go('/exam-setup?mode=create'),
            ),
          ),
        ),
      );
    }

    final currentIndex = _currentQuestionIndex.clamp(0, questions.length - 1);
    final currentQuestion = questions[currentIndex];
    final feedbackMessage = _feedbackForScore(
      quizProvider.scorePercent,
      quizProvider.weakTopics,
    );
    final nextStepMessage = _nextStepFor(
      quizProvider.scorePercent,
      quizProvider.weakTopics,
    );

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        exam?.title ?? 'Quiz session',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${currentIndex + 1}/${questions.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.deepBlue,
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizProvider.isSubmitted ? 'Quiz completed' : 'Topic practice quiz',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quizProvider.isSubmitted
                            ? 'Your score, weak areas, and answer review are ready below.'
                            : 'The quiz mixes multiple choice, fill-in-the-blank, and true/false questions based on your study topics.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (currentIndex + 1) / questions.length,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.aqua),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!quizProvider.isSubmitted) ...[
                  _QuestionCard(
                    question: currentQuestion,
                    questionNumber: currentIndex + 1,
                    totalQuestions: questions.length,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentIndex == 0
                              ? null
                              : () => setState(() => _currentQuestionIndex -= 1),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: currentIndex == questions.length - 1
                              ? () => _submitQuiz(context, quizProvider, studyProvider)
                              : () => setState(() => _currentQuestionIndex += 1),
                          child: Text(currentIndex == questions.length - 1 ? 'Submit' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _ResultCard(
                    scorePercent: quizProvider.scorePercent,
                    correctAnswers: quizProvider.correctAnswersCount,
                    totalQuestions: questions.length,
                    weakTopics: quizProvider.weakTopics,
                    feedbackMessage: feedbackMessage,
                    nextStepMessage: nextStepMessage,
                    onRetake: () {
                      quizProvider.resetQuiz();
                      setState(() => _currentQuestionIndex = 0);
                    },
                    onOpenFlashcards: () => context.go('/flashcards'),
                    onOpenStudyPlan: () => context.go('/study-plan'),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Answer review',
                    subtitle: 'Check the correct answers, read the explanations, and revisit the weak topics next.',
                  ),
                  const SizedBox(height: 16),
                  ...questions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _QuestionCard(
                            question: entry.value,
                            questionNumber: entry.key + 1,
                            totalQuestions: questions.length,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuiz(
    BuildContext context,
    QuizProvider quizProvider,
    StudyPlanProvider studyProvider,
  ) async {
    final hasUnanswered = quizProvider.questions.any((question) => !quizProvider.isQuestionAnswered(question));
    if (hasUnanswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer every question before submitting.')),
      );
      return;
    }

    quizProvider.submitQuiz();
    await studyProvider.recordQuizAttempt(
      correctAnswers: quizProvider.correctAnswersCount,
      totalQuestions: quizProvider.questions.length,
      weakTopics: quizProvider.weakTopics,
    );
  }

  String _feedbackForScore(int scorePercent, List<String> weakTopics) {
    if (scorePercent >= 85) {
      return 'Strong work. Your recall is improving and you are close to exam-ready performance.';
    }
    if (scorePercent >= 65) {
      return weakTopics.isEmpty
          ? 'Good progress. A short review round will help lock in your answers.'
          : 'You are improving, but a few weak areas still need another focused study block. The app will keep these topics in focus.';
    }
    return 'This quiz showed the topics that need more structure. Review the simpler explanations, then go back through the weak areas slowly.';
  }

  String _nextStepFor(int scorePercent, List<String> weakTopics) {
    if (scorePercent >= 85) {
      return 'Next step: do a fresh quiz tomorrow or switch to a mock-test style revision block.';
    }
    if (weakTopics.isEmpty) {
      return 'Next step: open your flashcards and repeat the hardest prompts once more today.';
    }
    return 'Next step: revisit ${weakTopics.take(2).join(' and ')} in your study plan. Recovery review tasks and stronger weak-area focus are now added automatically.';
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final selectedAnswer = quizProvider.answerFor(question.id);
    final isSubmitted = quizProvider.isSubmitted;
    final isCorrect = quizProvider.isCorrect(question);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question $questionNumber of $totalQuestions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              _InfoPill(
                label: question.type.label,
                color: AppTheme.primaryBlue,
                backgroundColor: AppTheme.blueSoft,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                label: question.difficultyLabel,
                color: AppTheme.mint,
                backgroundColor: AppTheme.greenSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                label: question.topicTitle,
                color: AppTheme.deepBlue,
                backgroundColor: AppTheme.blueSoft,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (question.hint != null) ...[
            const SizedBox(height: 10),
            Text(
              question.hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          if (question.type == QuizQuestionType.fillBlank)
            TextFormField(
              key: ValueKey('${question.id}-$isSubmitted'),
              initialValue: selectedAnswer ?? '',
              enabled: !isSubmitted,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              onChanged: (value) => context.read<QuizProvider>().updateTextAnswer(question.id, value),
            )
          else
            ...question.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionTile(
                  option: option,
                  isSubmitted: isSubmitted,
                  isSelected: selectedAnswer == option,
                  isCorrect: question.correctAnswer == option,
                  onTap: isSubmitted
                      ? null
                      : () => context.read<QuizProvider>().selectOption(question.id, option),
                ),
              ),
            ),
          if (isSubmitted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect ? AppTheme.greenSoft : AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCorrect ? AppTheme.mint : AppTheme.danger.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct answer' : 'Answer check',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCorrect ? AppTheme.mint : AppTheme.danger,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your answer: ${selectedAnswer ?? 'No answer'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Correct answer: ${question.correctAnswer}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.explanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (question.example != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      question.example!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.deepBlue,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSubmitted,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  final String option;
  final bool isSubmitted;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.line;
    Color backgroundColor = Colors.white;

    if (isSubmitted && isCorrect) {
      borderColor = AppTheme.mint;
      backgroundColor = AppTheme.greenSoft;
    } else if (isSubmitted && isSelected && !isCorrect) {
      borderColor = AppTheme.danger;
      backgroundColor = AppTheme.danger.withValues(alpha: 0.08);
    } else if (isSelected) {
      borderColor = AppTheme.primaryBlue;
      backgroundColor = AppTheme.blueSoft;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSubmitted
                  ? isCorrect
                      ? Icons.check_circle_rounded
                      : isSelected
                          ? Icons.cancel_rounded
                          : Icons.circle_outlined
                  : isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: borderColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.ink,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.scorePercent,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.weakTopics,
    required this.feedbackMessage,
    required this.nextStepMessage,
    required this.onRetake,
    required this.onOpenFlashcards,
    required this.onOpenStudyPlan,
  });

  final int scorePercent;
  final int correctAnswers;
  final int totalQuestions;
  final List<String> weakTopics;
  final String feedbackMessage;
  final String nextStepMessage;
  final VoidCallback onRetake;
  final VoidCallback onOpenFlashcards;
  final VoidCallback onOpenStudyPlan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$scorePercent%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$correctAnswers of $totalQuestions correct',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Feedback',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            feedbackMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text(
            'Weak areas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (weakTopics.isEmpty)
            Text(
              'No clear weak topic from this attempt. Keep your momentum with another short quiz tomorrow.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weakTopics
                  .map(
                    (topic) => _InfoPill(
                      label: topic,
                      color: AppTheme.danger,
                      backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 14),
          Text(
            'Next step',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            nextStepMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          AdaptiveButtonRow(
            first: OutlinedButton.icon(
              onPressed: onOpenFlashcards,
              icon: const Icon(Icons.layers_rounded),
              label: const Text('Flashcards'),
            ),
            second: FilledButton.icon(
              onPressed: onOpenStudyPlan,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Study plan'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetake,
              child: const Text('Retake quiz'),
            ),
          ),
        ],
      ),
    );
  }
}
