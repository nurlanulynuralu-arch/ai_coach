import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/subject_content_catalog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../services/study_material_parser.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
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
  String? _importedMaterialName;

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
    final topic = StudyMaterialParser.normalizeTopicTitle(
      subject: _selectedSubject,
      topic: (value ?? _topicController.text).trim(),
    );
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

  List<String> _materialSuggestions({int maxTopics = 8}) {
    return StudyMaterialParser.extractTopics(
      subject: _selectedSubject,
      content: _notesController.text,
      maxTopics: maxTopics,
    );
  }

  Future<void> _importMaterialFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md', 'csv', 'json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read this file. Try a text-based file instead.')),
      );
      return;
    }

    final importedText = StudyMaterialParser.normalizeImportedText(
      utf8.decode(bytes, allowMalformed: true),
    );
    if (importedText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The selected file is empty.')),
      );
      return;
    }

    final existingText = StudyMaterialParser.normalizeImportedText(_notesController.text);
    final mergedText = existingText.isEmpty ? importedText : '$existingText\n\n$importedText';

    setState(() {
      _notesController.text = StudyMaterialParser.normalizeImportedText(mergedText);
      _notesController.selection = TextSelection.collapsed(
        offset: _notesController.text.length,
      );
      _importedMaterialName = file.name;
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${file.name} to your study materials.')),
    );
  }

  void _addTopicsFromMaterials() {
    final suggestions = _materialSuggestions();
    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste study text or import a file first so the app can suggest topics.'),
        ),
      );
      return;
    }

    var addedCount = 0;
    setState(() {
      for (final topic in suggestions) {
        final alreadyExists = _topics.any(
          (existingTopic) => existingTopic.toLowerCase() == topic.toLowerCase(),
        );
        if (!alreadyExists) {
          _topics.add(topic);
          addedCount += 1;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          addedCount == 0
              ? 'All suggested topics are already in your list.'
              : 'Added $addedCount topic${addedCount == 1 ? '' : 's'} from your study materials.',
        ),
      ),
    );
  }

  void _clearNotes() {
    setState(() {
      _notesController.clear();
      _importedMaterialName = null;
    });
  }

  void _clearTopics() {
    setState(_topics.clear);
  }

  void _clearWeakAreas() {
    setState(_weakAreas.clear);
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mergedTopics = <String>[..._topics];
    for (final topic in _materialSuggestions(maxTopics: _topics.isEmpty ? 10 : 6)) {
      final alreadyExists = mergedTopics.any(
        (existingTopic) => existingTopic.toLowerCase() == topic.toLowerCase(),
      );
      if (!alreadyExists) {
        mergedTopics.add(topic);
      }
    }

    if (mergedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one topic or paste study materials to generate a plan.'),
        ),
      );
      return;
    }

    if (mergedTopics.length != _topics.length) {
      setState(() {
        _topics
          ..clear()
          ..addAll(mergedTopics);
      });
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
      topics: mergedTopics,
      weakAreas: _weakAreas,
      targetScore: _targetScore,
      notes: StudyMaterialParser.normalizeImportedText(_notesController.text),
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
    final topicPrompts = SubjectContentCatalog.topicPromptsFor(_selectedSubject);
    final weakAreaPrompts = SubjectContentCatalog.weakAreaPromptsFor(_selectedSubject);
    final topicHint = SubjectContentCatalog.topicHintFor(_selectedSubject);
    final normalizedMaterials = StudyMaterialParser.normalizeImportedText(_notesController.text);
    final materialLength = normalizedMaterials.length;
    final materialLimit = StudyMaterialParser.maxMaterialLength;
    final materialUsage = materialLimit == 0 ? 0.0 : materialLength / materialLimit;
    final materialStatusColor = materialUsage >= 0.85
        ? AppTheme.danger
        : materialUsage >= 0.55
            ? AppTheme.primaryBlue
            : AppTheme.mint;
    final materialSuggestions = _materialSuggestions()
        .where(
          (topic) => !_topics.any(
            (existingTopic) => existingTopic.toLowerCase() == topic.toLowerCase(),
          ),
        )
        .toList();

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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study materials',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Paste a syllabus, lesson summary, or import a text file. The app will suggest topics and use your material to build more relevant study guidance.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _notesController,
                          label: 'Text notes or source material',
                          hint: 'Paste chapters, lesson notes, revision points, or sample text here',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 8,
                          minLines: 6,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        AdaptiveButtonRow(
                          first: OutlinedButton.icon(
                            onPressed: _importMaterialFile,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Import text file'),
                          ),
                          second: FilledButton.tonalIcon(
                            onPressed: _addTopicsFromMaterials,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Suggest topics'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SetupStatChip(
                              label: '$materialLength / $materialLimit chars',
                              color: materialStatusColor,
                              backgroundColor: materialStatusColor.withValues(alpha: 0.12),
                              icon: Icons.straighten_rounded,
                            ),
                            _SetupStatChip(
                              label: '${materialSuggestions.length} suggestions ready',
                              color: AppTheme.primaryBlue,
                              backgroundColor: AppTheme.blueSoft,
                              icon: Icons.lightbulb_outline_rounded,
                            ),
                            _SetupStatChip(
                              label: '${_topics.length} topics selected',
                              color: AppTheme.mint,
                              backgroundColor: AppTheme.greenSoft,
                              icon: Icons.topic_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _importedMaterialName == null
                              ? 'Supported files: .txt, .md, .csv, .json'
                              : 'Loaded file: $_importedMaterialName',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (normalizedMaterials.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _clearNotes,
                              icon: const Icon(Icons.delete_sweep_outlined),
                              label: const Text('Clear study materials'),
                            ),
                          ),
                        ],
                        if (materialSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: materialSuggestions.take(6).map((topic) {
                              return ActionChip(
                                label: Text(topic),
                                onPressed: () => _addTopic(topic),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Student analysis',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (_weakAreas.isNotEmpty)
                              TextButton(
                                onPressed: _clearWeakAreas,
                                child: const Text('Clear all'),
                              ),
                          ],
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
                                hint: weakAreaPrompts.take(2).join(' or '),
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
                          children: weakAreaPrompts.take(6).map((weakArea) {
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Study topics',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (_topics.isNotEmpty)
                              TextButton(
                                onPressed: _clearTopics,
                                child: const Text('Clear all'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add the chapters, concepts, or weak areas that should be scheduled in the study plan.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _topics.isEmpty
                              ? 'Pick at least one topic so the generated plan stays focused.'
                              : '${_topics.length} topic${_topics.length == 1 ? '' : 's'} ready for plan generation.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _topicController,
                                label: 'Add a topic',
                                hint: topicHint,
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
                          children: topicPrompts.take(8).map((topic) {
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

class _SetupStatChip extends StatelessWidget {
  const _SetupStatChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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
