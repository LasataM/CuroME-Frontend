import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/widgets/common_widgets.dart';

class CaregiverVisitNotesTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const CaregiverVisitNotesTab({super.key, required this.onBack});

  @override
  ConsumerState<CaregiverVisitNotesTab> createState() =>
      _CaregiverVisitNotesTabState();
}

class _CaregiverVisitNotesTabState
    extends ConsumerState<CaregiverVisitNotesTab> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final patientId = state.linkedCaregiverPatientId;
    final notes = state.visitNotesForPatient(patientId).reversed.toList();

    return Column(
      children: [
        PageHeader(title: 'Visit Notes', onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log Visit Note',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Write your visit note here…',
                          filled: true,
                          fillColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_noteCtrl.text.trim().isEmpty) return;
                          state.addVisitNote(_noteCtrl.text.trim());
                          _noteCtrl.clear();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600),
                        child: const Text('Save & Timestamp Note',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('PREVIOUS NOTES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              if (notes.isEmpty)
                const EmptyState(icon: Icons.description, text: 'No notes yet.')
              else
                for (final n in notes)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.note, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(n.timestamp,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
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
