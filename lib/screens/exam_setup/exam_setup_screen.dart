import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({
    super.key,
    this.forceCreate = false,
  });

  final bool forceCreate;

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _topicController = TextEditingController();
  final _weakAreaController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedSubject;
  late String _selectedStudyLevel;
  late String _selectedExamType;
  late String _selectedDifficulty;
  late DateTime _selectedDate;
  late int _targetScore;
  final List<String> _topics = <String>[];
  final List<String> _weakAreas = <String>[];
  bool _initialized = false;

  @override
  void dispose() {
    _examNameController.dispose();
    _topicController.dispose();
    _weakAreaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final authUser = context.read<AuthProvider>().user;
    final existingExam = widget.forceCreate ? null : context.read<StudyPlanProvider>().activeExam;

    _selectedSubject = existingExam?.subject ??
        authUser?.selectedSubjects.firstOrNull ??
        AppConstants.subjects.first;
    _selectedStudyLevel = existingExam?.studyLevel ?? AppConstants.studyLevels[2];
    _selectedExamType = existingExam?.examType ?? AppConstants.examTypes.first;
    _selectedDifficulty = existingExam?.difficulty ?? AppConstants.difficulties[1];
    _selectedDate = existingExam?.examDate ?? DateTime.now().add(const Duration(days: 21));
    _targetScore = existingExam?.targetScore ?? 85;
    _examNameController.text = existingExam?.title ?? '';
    _notesController.text = existingExam?.notes ?? '';
    _topics.addAll(existingExam?.topics.map((topic) => topic.title) ?? const <String>[]);
    _weakAreas.addAll(existingExam?.weakAreas ?? const <String>[]);

    _initialized = true;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: _selectedDate,
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _addTopic([String? value]) {
    final topic = (value ?? _topicController.text).trim();
    if (topic.isEmpty) {
      return;
    }

    final alreadyExists = _topics.any((item) => item.toLowerCase() == topic.toLowerCase());
    if (alreadyExists) {
      _topicController.clear();
      return;
    }

    setState(() {
      _topics.add(topic);
      _topicController.clear();
    });
  }

  void _addWeakArea([String? value]) {
    final weakArea = (value ?? _weakAreaController.text).trim();
    if (weakArea.isEmpty) {
      return;
    }

    final alreadyExists = _weakAreas.any((item) => item.toLowerCase() == weakArea.toLowerCase());
    if (alreadyExists) {
      _weakAreaController.clear();
      return;
    }

    setState(() {
      _weakAreas.add(weakArea);
      _weakAreaController.clear();
    });
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one topic to generate a plan.')),
      );
      return;
    }

    final provider = context.read<StudyPlanProvider>();
    final existingExam = widget.forceCreate ? null : provider.activeExam;
    final success = await provider.saveExamPlan(
      examId: existingExam?.id,
      subject: _selectedSubject,
      examName: _examNameController.text.trim(),
      studyLevel: _selectedStudyLevel,
      examType: _selectedExamType,
      examDate: _selectedDate,
      difficulty: _selectedDifficulty,
      topics: _topics,
      weakAreas: _weakAreas,
      targetScore: _targetScore,
      notes: _notesController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingExam == null ? 'Study plan generated successfully.' : 'Exam updated successfully.',
          ),
        ),
      );
      context.go('/study-plan');
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }

  Future<void> _deleteExam() async {
    final provider = context.read<StudyPlanProvider>();
    final exam = provider.activeExam;
    if (exam == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete exam?'),
              content: const Text(
                'This will delete the exam, study tasks, flashcards, and quiz attempts from Firestore.',
              ),
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

    if (!confirmed) {
      return;
    }

    await provider.deleteExam(exam.id);
    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPlanProvider>();
    final existingExam = widget.forceCreate ? null : provider.activeExam;

    return Scaffold(
      appBar: AppBar(
        title: Text(existingExam == null ? 'Create exam' : 'Edit exam'),
        actions: [
          if (existingExam != null)
            TextButton(
              onPressed: () => context.go('/exam-setup?mode=create'),
              child: const Text('New exam'),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Exam setup',
                    subtitle:
                        'Add your exam details and topics. The app will spread study tasks across the days before the exam.',
                  ),
                  const SizedBox(height: 16),
                  InfoBanner(
                    title: 'How plan generation works',
                    message:
                        'The planner uses your level, exam type, exam date, weak areas, topic list, and target score to build daily tasks, revision days, quizzes, and flashcards.',
                    icon: Icons.auto_awesome_rounded,
                    backgroundColor: AppTheme.greenSoft,
                    foregroundColor: AppTheme.mint,
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSubject,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.menu_book_rounded),
                          ),
                          items: AppConstants.subjects
                              .map(
                                (subject) => DropdownMenuItem(
                                  value: subject,
                                  child: Text(subject),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSubject = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _examNameController,
                          label: 'Exam title',
                          hint: 'e.g. Biology Midterm',
                          prefixIcon: Icons.school_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the exam title.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStudyLevel,
                          decoration: const InputDecoration(
                            labelText: 'Student level',
                            prefixIcon: Icon(Icons.bar_chart_rounded),
                          ),
                          items: AppConstants.studyLevels
                              .map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStudyLevel = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedExamType,
                          decoration: const InputDecoration(
                            labelText: 'Exam type',
                            prefixIcon: Icon(Icons.fact_check_outlined),
                          ),
                          items: AppConstants.examTypes
                              .map(
                                (examType) => DropdownMenuItem(
                                  value: examType,
                                  child: Text(examType),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedExamType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Exam date',
                              prefixIcon: Icon(Icons.calendar_month_rounded),
                            ),
                            child: Text(
                              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.ink,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Target score',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.targetScoreOptions.map((score) {
                            return ChoiceChip(
                              label: Text('$score%'),
                              selected: _targetScore == score,
                              onSelected: (_) {
                                setState(() => _targetScore = score);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Difficulty',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.difficulties.map((difficulty) {
                            return ChoiceChip(
                              label: Text(difficulty),
                              selected: _selectedDifficulty == difficulty,
                              onSelected: (_) {
                                setState(() => _selectedDifficulty = difficulty);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'Optional exam notes, focus areas, or instructions',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                          minLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student analysis',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell the coach where you feel weak so the plan can repeat difficult material later.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _weakAreaController,
                                label: 'Weak area',
                                hint: 'e.g. Vocabulary or Problem solving',
                                prefixIcon: Icons.flag_outlined,
                                onFieldSubmitted: _addWeakArea,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _addWeakArea,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(64, 56),
                              ),
                              child: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.weakAreaPrompts.take(5).map((weakArea) {
                            return ActionChip(
                              label: Text(weakArea),
                              onPressed: () => _addWeakArea(weakArea),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        if (_weakAreas.isEmpty)
                          Text(
                            'No weak areas added yet. You can still continue, but adding them makes the plan more personal.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _weakAreas
                                .map(
                                  (weakArea) => Chip(
                                    label: Text(weakArea),
                                    onDeleted: () => setState(() => _weakAreas.remove(weakArea)),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study topics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add the chapters, concepts, or weak areas that should be scheduled in the study plan.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _topicController,
                                label: 'Add a topic',
                                hint: 'e.g. Photosynthesis',
                                prefixIcon: Icons.topic_outlined,
                                onFieldSubmitted: _addTopic,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _addTopic,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(64, 56),
                              ),
                              child: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.emptyTopicPrompts.take(4).map((topic) {
                            return ActionChip(
                              label: Text(topic),
                              onPressed: () => _addTopic(topic),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        if (_topics.isEmpty)
                          Text(
                            'No topics added yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _topics
                                .map(
                                  (topic) => Chip(
                                    label: Text(topic),
                                    onDeleted: () => setState(() => _topics.remove(topic)),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: existingExam == null
                        ? 'Generate study plan'
                        : 'Save changes and regenerate plan',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: provider.isLoading,
                    onPressed: _saveExam,
                  ),
                  if (existingExam != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteExam,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete exam'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
