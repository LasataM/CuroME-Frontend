import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class CaregiverSuggestionsTab extends ConsumerWidget {
  final VoidCallback onBack;

  const CaregiverSuggestionsTab({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final suggestions = state.caregiverSuggestions.reversed.toList();
    final patientName = state.linkedPatientName.isEmpty
        ? 'your patient'
        : state.linkedPatientName;

    return Column(
      children: [
        PageHeader(title: 'Suggestions', onBack: onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Suggestions for $patientName',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800)),
                          Text(
                              '${suggestions.length} recommendation${suggestions.length == 1 ? "" : "s"} available',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (suggestions.isEmpty)
                const EmptyState(
                    icon: Icons.assignment,
                    text: 'No doctor suggestions for this patient yet.')
              else
                for (final suggestion in suggestions)
                  _caregiverSuggestionCard(suggestion),
            ],
          ),
        ),
      ],
    );
  }

  Widget _caregiverSuggestionCard(PatientSuggestion suggestion) {
    final typeIcon = suggestion.type == 'activity'
        ? Icons.directions_walk
        : suggestion.type == 'followup'
            ? Icons.calendar_month
            : Icons.medication;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border(
          left: BorderSide(
            color: suggestion.priority == Priority.high
                ? Colors.red
                : suggestion.priority == Priority.medium
                    ? Colors.amber
                    : Colors.green,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(suggestion.type,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const Spacer(),
              PriorityBadge(priority: suggestion.priority),
            ],
          ),
          const SizedBox(height: 8),
          Text(suggestion.text,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(suggestion.rationale,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('From ${suggestion.from}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
        ],
      ),
    );
  }
}
