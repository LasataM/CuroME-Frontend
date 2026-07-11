import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class DoctorVisitNotesTab extends ConsumerWidget {
  final VoidCallback onBack;

  const DoctorVisitNotesTab({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final patients = state.doctorVisiblePatients;
    if (patients.isNotEmpty &&
        !patients.any((patient) => patient.id == state.selectedPatientId)) {
      state.selectedPatientId = patients.first.id;
    }
    final patient =
        patients.where((p) => p.id == state.selectedPatientId).isEmpty
            ? null
            : patients.firstWhere((p) => p.id == state.selectedPatientId);
    final notes = state
        .visitNotesForPatientAndDoctor(
            state.selectedPatientId, state.currentAccountEmail)
        .reversed
        .toList();

    return Column(
      children: [
        PageHeader(
          title: 'Visit Notes',
          onBack: onBack,
        ),
        PatientSelector(
          patients: patients,
          selectedId: state.selectedPatientId,
          onSelect: state.selectPatient,
        ),
        Expanded(
          child: patient == null
              ? const EmptyState(icon: Icons.person, text: 'No patients yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        PatientAvatar(patient: patient, size: 40),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                                '${notes.length} visit note${notes.length != 1 ? "s" : ""}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (notes.isEmpty)
                      const EmptyState(
                          icon: Icons.description, text: 'No visit notes yet.')
                    else
                      for (final note in notes) _visitNoteCard(note),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _visitNoteCard(VisitNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border:
            Border(left: BorderSide(color: Colors.amber.shade700, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(note.from,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              Text(note.timestamp,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(note.note, style: const TextStyle(fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}
