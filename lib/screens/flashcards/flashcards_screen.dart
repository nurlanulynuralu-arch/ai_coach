import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard.dart';
import '../../models/study_task.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/flashcard_panel.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/topic_practice_sheet.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.96);
  int _currentIndex = 0;
  bool _showBack = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPlanProvider>();
    final exam = provider.activeExam;
    final cards = provider.flashcards;
    final activeCard = cards.isEmpty ? null : cards[min(_currentIndex, cards.length - 1)];

    if (provider.isLoading && cards.isEmpty) {
      return const Scaffold(body: LoadingStateView());
    }

    return Scaffold(
      floatingActionButton: exam == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openFlashcardEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add card'),
            ),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to home',
        ),
        title: const Text('Flashcards'),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: exam == null
              ? EmptyStateView(
                  title: 'No active exam',
                  message: 'Create an exam first to build a flashcard deck.',
                  icon: Icons.layers_outlined,
                  actionLabel: 'Create exam',
                  onAction: () => context.go('/exam-setup?mode=create'),
                )
              : cards.isEmpty
                  ? EmptyStateView(
                      title: 'No flashcards yet',
                      message:
                          'Generate a study plan or add a custom flashcard. When internet knowledge is available, the deck is enriched with topic summaries.',
                      icon: Icons.style_outlined,
                      actionLabel: 'Add flashcard',
                      onAction: () => _openFlashcardEditor(context),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Flip cards, mark mastery, and edit the deck when needed.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '${_currentIndex + 1}/${cards.length} cards',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 430,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: cards.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                  _showBack = false;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: FlashcardPanel(
                                    card: cards[index],
                                    showBack: index == _currentIndex && _showBack,
                                    onTap: () {
                                      if (index != _currentIndex) {
                                        return;
                                      }
                                      setState(() => _showBack = !_showBack);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          if (activeCard != null) ...[
                            const SizedBox(height: 18),
                            AppCard(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFEAF6FF),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Topic practice',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activeCard.topicTitle,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.primaryBlue,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.topicSummaryFor(activeCard.topicTitle) ?? activeCard.back,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _TopicMetaChip(
                                        label:
                                            '${provider.tasksForTopic(activeCard.topicTitle).length} related tasks',
                                        icon: Icons.checklist_rounded,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      _TopicMetaChip(
                                        label:
                                            '${provider.flashcardsForTopic(activeCard.topicTitle).length} cards',
                                        icon: Icons.layers_rounded,
                                        color: AppTheme.mint,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AdaptiveButtonRow(
                                    first: OutlinedButton.icon(
                                      onPressed: () => _openTopicPractice(context, activeCard),
                                      icon: const Icon(Icons.menu_book_rounded),
                                      label: const Text('Open topic'),
                                    ),
                                    second: FilledButton.icon(
                                      onPressed: () =>
                                          _startTopicQuiz(context, activeCard.topicTitle),
                                      icon: const Icon(Icons.quiz_rounded),
                                      label: const Text('Topic quiz'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          AdaptiveButtonRow(
                            first: OutlinedButton.icon(
                              onPressed: () {
                                final activeCard = cards[min(_currentIndex, cards.length - 1)];
                                provider.reviewFlashcard(activeCard.id, mastered: false);
                                _moveToNext(cards.length);
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Needs review'),
                            ),
                            second: FilledButton.icon(
                              onPressed: () {
                                final activeCard = cards[min(_currentIndex, cards.length - 1)];
                                provider.reviewFlashcard(activeCard.id, mastered: true);
                                _moveToNext(cards.length);
                              },
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('Mastered'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdaptiveButtonRow(
                            first: OutlinedButton.icon(
                              onPressed: () {
                                final activeCard = cards[min(_currentIndex, cards.length - 1)];
                                _openFlashcardEditor(context, flashcard: activeCard);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit card'),
                            ),
                            second: OutlinedButton.icon(
                              onPressed: () => _deleteFlashcard(
                                context,
                                cards[min(_currentIndex, cards.length - 1)].id,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete card'),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  void _moveToNext(int cardCount) {
    if (cardCount == 0) {
      return;
    }

    if (_currentIndex >= cardCount - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great work. You finished this flashcard round.')),
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _deleteFlashcard(BuildContext context, String flashcardId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete flashcard?'),
              content: const Text('This card will be removed from Firestore.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<StudyPlanProvider>().deleteFlashcard(flashcardId);
  }

  Future<void> _openTopicPractice(BuildContext context, Flashcard card) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<StudyPlanProvider>(
          builder: (sheetContext, provider, _) {
            final topicTasks = provider.tasksForTopic(card.topicTitle);
            final summary = provider.topicSummaryFor(card.topicTitle) ?? card.back;

            return TopicPracticeSheet(
              topicTitle: card.topicTitle,
              summary: summary,
              masteryLabel: _masteryLabelFor(card),
              relatedCardCount: provider.flashcardsForTopic(card.topicTitle).length,
              tasks: topicTasks,
              prompts: _buildPracticePrompts(
                card: card,
                tasks: topicTasks,
                summary: summary,
              ),
              onToggleTask: (task) => provider.toggleTask(task.id),
              onStartQuiz: () {
                Navigator.pop(sheetContext);
                _startTopicQuiz(context, card.topicTitle);
              },
              onOpenStudyPlan: () {
                Navigator.pop(sheetContext);
                context.go('/study-plan');
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startTopicQuiz(BuildContext context, String topicTitle) async {
    final studyProvider = context.read<StudyPlanProvider>();
    final activeExam = studyProvider.activeExam;
    final questions = studyProvider.buildQuizQuestions(
      focusTopics: [topicTitle],
    );

    if (questions.isEmpty && activeExam == null) {
      context.go('/study-plan');
      return;
    }

    final quizProvider = context.read<QuizProvider>();
    if (questions.isEmpty) {
      await quizProvider.loadFallbackQuestions(
        subject: activeExam!.subject,
        topics: [topicTitle],
      );
    } else {
      quizProvider.setQuestions(questions);
    }

    if (!context.mounted) {
      return;
    }
    context.go('/quiz');
  }

  String _masteryLabelFor(Flashcard card) {
    return switch (card.reviewStage) {
      >= 4 => 'Mastered',
      >= 2 => 'Growing',
      _ => 'Needs review',
    };
  }

  List<TopicPracticePrompt> _buildPracticePrompts({
    required Flashcard card,
    required List<StudyTask> tasks,
    required String summary,
  }) {
    final shortenedSummary = summary.length > 140 ? '${summary.substring(0, 137)}...' : summary;
    final hasQuizTask = tasks.any((task) => task.taskType.toLowerCase() == 'quiz');
    final hasRecallTask = tasks.any((task) => task.taskType.toLowerCase() == 'recall');

    return [
      TopicPracticePrompt(
        title: 'Explain it from memory',
        description:
            'Without reading your notes, explain ${card.topicTitle} in 3-4 sentences and then compare with: $shortenedSummary',
        icon: Icons.record_voice_over_rounded,
        color: AppTheme.primaryBlue,
      ),
      TopicPracticePrompt(
        title: hasQuizTask ? 'Do the timed check' : 'Write one exam-style question',
        description: hasQuizTask
            ? 'Open the topic quiz and answer at least one timed question on ${card.topicTitle}.'
            : 'Create one short exam-style question on ${card.topicTitle} and answer it in your own words.',
        icon: Icons.timer_rounded,
        color: AppTheme.deepBlue,
      ),
      TopicPracticePrompt(
        title: hasRecallTask ? 'Finish the recall step' : 'Create three key takeaways',
        description: hasRecallTask
            ? 'Use the linked recall task and write everything you remember about ${card.topicTitle} for two minutes.'
            : 'Write three key facts, one example, and one common mistake for ${card.topicTitle}.',
        icon: Icons.lightbulb_rounded,
        color: AppTheme.mint,
      ),
    ];
  }

  Future<void> _openFlashcardEditor(
    BuildContext context, {
    Flashcard? flashcard,
  }) async {
    final topicController = TextEditingController(text: flashcard?.topicTitle ?? '');
    final frontController = TextEditingController(text: flashcard?.front ?? '');
    final backController = TextEditingController(text: flashcard?.back ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(flashcard == null ? 'Add flashcard' : 'Edit flashcard'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: topicController,
                    label: 'Topic',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a topic.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: frontController,
                    label: 'Front',
                    maxLines: 2,
                    minLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter front text.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: backController,
                    label: 'Back',
                    maxLines: 4,
                    minLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter back text.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final success = await context.read<StudyPlanProvider>().saveFlashcardDraft(
                      flashcardId: flashcard?.id,
                      topicTitle: topicController.text.trim(),
                      front: frontController.text.trim(),
                      back: backController.text.trim(),
                    );
                if (!dialogContext.mounted) {
                  return;
                }
                if (success) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    topicController.dispose();
    frontController.dispose();
    backController.dispose();
  }
}

class _TopicMetaChip extends StatelessWidget {
  const _TopicMetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
