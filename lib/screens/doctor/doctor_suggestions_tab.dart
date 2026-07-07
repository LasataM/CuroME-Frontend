import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class DoctorSuggestionsTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DoctorSuggestionsTab({super.key, required this.onBack});

  @override
  ConsumerState<DoctorSuggestionsTab> createState() =>
      _DoctorSuggestionsTabState();
}

class _DoctorSuggestionsTabState extends ConsumerState<DoctorSuggestionsTab> {
  bool _showAddSugg = false;
  String _suggType = 'activity';
  Priority _suggPriority = Priority.medium;
  final _suggTextCtrl = TextEditingController();
  final _suggRationaleCtrl = TextEditingController();

  @override
  void dispose() {
    _suggTextCtrl.dispose();
    _suggRationaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final patient = state.selectedPatient;
    final current = state.suggestions
        .where((s) => s.patientId == state.selectedPatientId)
        .toList();

    return Column(
      children: [
        PageHeader(
          title: 'Suggestions',
          onBack: widget.onBack,
          action: IconButton(
            icon: Icon(_showAddSugg ? Icons.close : Icons.add,
                color: Colors.green.shade700),
            onPressed: () => setState(() => _showAddSugg = !_showAddSugg),
          ),
        ),
        PatientSelector(
          patients: state.patients,
          selectedId: state.selectedPatientId,
          onSelect: (id) => setState(() => state.selectedPatientId = id),
        ),
        Expanded(
          child: patient == null
              ? const EmptyState(icon: Icons.person, text: 'No patients yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_showAddSugg) _addSuggestionForm(state, patient),
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
                                '${current.length} active recommendation${current.length != 1 ? "s" : ""}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (current.isEmpty)
                      const EmptyState(
                          icon: Icons.assignment, text: 'No suggestions yet.')
                    else
                      for (final s in current) _suggestionCard(s),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _addSuggestionForm(AppState state, PatientProfile patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Suggestion for ${patient.shortName}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: ['activity', 'medication', 'followup'].map((t) {
              final sel = _suggType == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => _suggType = t),
                selectedColor: Colors.green.shade600,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : Colors.black87),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: Priority.values.map((p) {
              final sel = _suggPriority == p;
              return ChoiceChip(
                label: Text(p.name),
                selected: sel,
                onSelected: (_) => setState(() => _suggPriority = p),
                selectedColor: AppColors.indigo,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : Colors.black87),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _suggTextCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Recommendation…',
                filled: true,
                fillColor: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _suggRationaleCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Rationale (optional)…',
                filled: true,
                fillColor: Colors.white),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_suggTextCtrl.text.trim().isEmpty) return;
                state.addSuggestion(PatientSuggestion(
                  id: newId(),
                  patientId: patient.id,
                  type: _suggType,
                  text: _suggTextCtrl.text.trim(),
                  rationale: _suggRationaleCtrl.text.trim().isEmpty
                      ? 'No rationale provided.'
                      : _suggRationaleCtrl.text.trim(),
                  priority: _suggPriority,
                  from: state.doctorDisplayName,
                ));
                setState(() {
                  _showAddSugg = false;
                  _suggTextCtrl.clear();
                  _suggRationaleCtrl.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
              child: const Text('Send to Patient & Caregiver',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(PatientSuggestion s) {
    final typeIcon = s.type == 'activity'
        ? Icons.directions_walk
        : s.type == 'followup'
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
                color: s.priority == Priority.high
                    ? Colors.red
                    : s.priority == Priority.medium
                        ? Colors.amber
                        : Colors.green,
                width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(s.type,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const Spacer(),
              PriorityBadge(priority: s.priority),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.text,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(s.rationale,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
