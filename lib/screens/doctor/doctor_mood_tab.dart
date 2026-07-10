import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/widgets/mood_chart.dart';

class DoctorMoodTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DoctorMoodTab({super.key, required this.onBack});

  @override
  ConsumerState<DoctorMoodTab> createState() => _DoctorMoodTabState();
}

class _DoctorMoodTabState extends ConsumerState<DoctorMoodTab> {
  String _moodPatientId = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final patients = state.doctorVisiblePatients;
    final selectedVisible =
        patients.any((patient) => patient.id == state.selectedPatientId);
    if ((_moodPatientId.isEmpty ||
            !patients.any((patient) => patient.id == _moodPatientId)) &&
        patients.isNotEmpty) {
      _moodPatientId = selectedVisible
          ? state.selectedPatientId
          : patients.first.id;
    }

    final patient = patients.where((p) => p.id == _moodPatientId).isEmpty
        ? (patients.isNotEmpty ? patients.first : null)
        : patients.firstWhere((p) => p.id == _moodPatientId);
    final data = state.patientMoodData[_moodPatientId] ?? [];

    return Column(
      children: [
        PageHeader(
          title: 'Mood Trends',
          onBack: widget.onBack,
        ),
        if (patients.isNotEmpty)
          PatientSelector(
            patients: patients,
            selectedId: _moodPatientId,
            onSelect: (id) => setState(() => _moodPatientId = id),
          ),
        Expanded(
          child: patient == null
              ? const EmptyState(icon: Icons.person, text: 'No patients yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        PatientAvatar(patient: patient, size: 36),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const Text('7-day mood history',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MoodAreaChart(
                        data: data,
                        label: 'Mood Score (1 = Very Sad · 5 = Very Happy)'),
                    const SizedBox(height: 16),
                    const Text('CHECK-IN HISTORY',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (data.isEmpty)
                      const EmptyState(
                          icon: Icons.trending_up, text: 'No mood data yet.')
                    else
                      for (final entry in data.reversed.take(7))
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
