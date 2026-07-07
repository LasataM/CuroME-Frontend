import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/screens/patient/patient_widgets.dart';

class PatientMedicinesTab extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const PatientMedicinesTab(
      {super.key, required this.onBack, required this.onHome});

  void _confirmReminder(
      BuildContext context, String id, String label, AppState state) {
    state.takeMedicationReminder(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label marked as taken. Caregiver notified.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final reminders = state.medicationReminders;
    final allDone = reminders.isNotEmpty && reminders.every((r) => r.confirmed);
    return Column(
      children: [
        PatientPageHeader(
          title: 'Take Medicine',
          breadcrumb: 'Home > Medicines',
          onBack: onBack,
          onHome: onHome,
        ),
        Expanded(
          child: reminders.isEmpty
              ? Center(
                  child: Text('No medications scheduled.',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  children: [
                    Text('Your medicines for today, ${state.patientFirstName}:',
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xFF555555))),
                    const SizedBox(height: 14),
                    for (var i = 0; i < reminders.length; i++) ...[
                      _medicineStepCard(
                          context, state, reminders[i], i, reminders.length),
                      const SizedBox(height: 12),
                    ],
                    if (allDone)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(
                              color: Colors.green.shade600, width: 2),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.star,
                                size: 44, color: Colors.amber.shade600),
                            const SizedBox(height: 10),
                            Text('All done, ${state.patientFirstName}!',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green.shade700)),
                            const SizedBox(height: 6),
                            const Text('You took all your medicines today.',
                                style: TextStyle(
                                    fontSize: 15, color: Color(0xFF555555))),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _medicineStepCard(BuildContext context, AppState state, Reminder r,
      int index, int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: r.confirmed ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        border: Border.all(
            color:
                r.confirmed ? Colors.green.shade600 : const Color(0xFFD97706),
            width: 2),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'STEP ${index + 1} OF $total  •  ${r.confirmed ? "DONE" : "TO DO"}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: r.confirmed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.medication,
                    color: r.confirmed
                        ? Colors.green.shade600
                        : const Color(0xFFD97706),
                    size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.patientText)),
                    Text(
                        'Take ${r.date.isEmpty ? "today" : "on ${r.date}"} at ${r.time}',
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF555555))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (r.confirmed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text('Taken — well done!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D))),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReminder(context, r.id, r.label, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('I took this medicine',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
