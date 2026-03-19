import 'package:flutter/material.dart';

import '../models/topic_search_result.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class TopicSearchResultsPanel extends StatefulWidget {
  const TopicSearchResultsPanel({
    super.key,
    required this.topicTitle,
    required this.results,
    required this.isLoading,
    required this.onRefresh,
    this.errorMessage,
  });

  final String topicTitle;
  final List<TopicSearchResult> results;
  final bool isLoading;
  final VoidCallback onRefresh;
  final String? errorMessage;

  @override
  State<TopicSearchResultsPanel> createState() => _TopicSearchResultsPanelState();
}

class _TopicSearchResultsPanelState extends State<TopicSearchResultsPanel> {
  TopicSearchSortMode _sortMode = TopicSearchSortMode.bestMatch;

  @override
  Widget build(BuildContext context) {
    final sortedResults = sortTopicSearchResults(
      widget.results,
      _sortMode,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Internet results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Relevant web information for ${widget.topicTitle}, sorted so the strongest match is easy to review first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh results',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.results.isNotEmpty)
            DropdownButtonFormField<TopicSearchSortMode>(
              initialValue: _sortMode,
              decoration: const InputDecoration(
                labelText: 'Sort results',
                prefixIcon: Icon(Icons.sort_rounded),
              ),
              items: TopicSearchSortMode.values
                  .map(
                    (mode) => DropdownMenuItem<TopicSearchSortMode>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _sortMode = value);
              },
            ),
          if (widget.results.isNotEmpty) const SizedBox(height: 16),
          if (widget.isLoading && widget.results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.errorMessage != null && widget.results.isEmpty)
            _ErrorState(
              message: widget.errorMessage!,
              onRefresh: widget.onRefresh,
            )
          else if (sortedResults.isEmpty)
            _EmptyState(onRefresh: widget.onRefresh)
          else
            ...sortedResults.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == sortedResults.length - 1 ? 0 : 12),
                child: _TopicSearchResultTile(
                  index: entry.key + 1,
                  result: entry.value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicSearchResultTile extends StatelessWidget {
  const _TopicSearchResultTile({
    required this.index,
    required this.result,
  });

  final int index;
  final TopicSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                label: '#$index',
                color: AppTheme.primaryBlue,
                backgroundColor: AppTheme.blueSoft,
              ),
              _MetaChip(
                label: result.sourceLabel,
                color: result.isFallback ? AppTheme.deepBlue : AppTheme.mint,
                backgroundColor: result.isFallback ? AppTheme.blueSoft : AppTheme.greenSoft,
              ),
              if (result.description != null && result.description!.isNotEmpty)
                _MetaChip(
                  label: result.description!,
                  color: AppTheme.deepBlue,
                  backgroundColor: AppTheme.blueSoft,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            result.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (result.sourceUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(
              result.sourceUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRefresh,
  });

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No matching internet results were found yet for this exact topic.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.travel_explore_rounded),
          label: const Text('Search again'),
        ),
      ],
    );
  }
}
