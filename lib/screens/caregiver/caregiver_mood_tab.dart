import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/widgets/mood_chart.dart';

class CaregiverMoodTab extends ConsumerWidget {
  final VoidCallback onBack;

  const CaregiverMoodTab({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final moodHistory =
        state.patientMoodData[state.linkedCaregiverPatientId] ?? const [];
    final recent = moodHistory.length > 7
        ? moodHistory.sublist(moodHistory.length - 7)
        : moodHistory;
    return Column(
      children: [
        PageHeader(title: 'Mood Check-ins', onBack: onBack),
        Expanded(
          child: moodHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.trending_up, text: 'No mood data yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    MoodAreaChart(data: recent, label: '7-Day Mood Timeline'),
                    const SizedBox(height: 16),
                    for (final entry in moodHistory.reversed)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            MoodIcon(mood: entry.mood, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(entry.date,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400)),
                                ],
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 30,
                              decoration: BoxDecoration(
                                color: moodColors[entry.mood],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
