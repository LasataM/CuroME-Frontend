import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/patient/patient_tab.dart';
import 'package:curome/screens/patient/patient_widgets.dart';

class PatientMessagesTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const PatientMessagesTab(
      {super.key, required this.onBack, required this.onHome});

  @override
  ConsumerState<PatientMessagesTab> createState() => _PatientMessagesTabState();
}

class _PatientMessagesTabState extends ConsumerState<PatientMessagesTab> {
  bool _inThread = false;
  PtMsgTab _msgTab = PtMsgTab.doctor;
  String? _selectedDoctorEmail;
  String? _selectedCaregiverEmail;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final patientId = _patientThreadId(state);
    final assignedDoctors = state.doctorsForPatient(patientId);
    final caregivers = state.caregiversForPatient(patientId);

    if (!_inThread) {
      return Column(
        children: [
          PatientPageHeader(
            title: 'Messages',
            breadcrumb: 'Home > Messages',
            onBack: widget.onBack,
            onHome: widget.onHome,
          ),
          Expanded(
            child: ListView(
              children: [
                for (final doctor in assignedDoctors)
                  _messageTile(
                    icon: Icons.medical_services,
                    color: AppColors.indigo,
                    title: state.doctorDisplayNameForAccount(doctor),
                    subtitle: _lastPreview(
                        state.patientDoctorThread(patientId, doctor.email)),
                    onTap: () => setState(() {
                      _msgTab = PtMsgTab.doctor;
                      _selectedDoctorEmail = doctor.email;
                      _inThread = true;
                    }),
                  ),
                for (final caregiver in caregivers)
                  _messageTile(
                    initials: _initialsFor(caregiver.name, fallback: 'C'),
                    color: AppColors.emerald,
                    title: caregiver.name,
                    subtitle: _lastPreview(state.caregiverPatientThread(patientId,
                        caregiverEmail: caregiver.email)),
                    onTap: () => setState(() {
                      _msgTab = PtMsgTab.caregiver;
                      _selectedCaregiverEmail = caregiver.email;
                      _inThread = true;
                    }),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final isDoctor = _msgTab == PtMsgTab.doctor;
    final selectedDoctorMatches = assignedDoctors
        .where((doctor) => doctor.email == _selectedDoctorEmail)
        .toList();
    final selectedDoctor =
        selectedDoctorMatches.isEmpty ? null : selectedDoctorMatches.first;
    final thread = isDoctor
        ? (_selectedDoctorEmail == null
            ? const <ChatMessage>[]
            : state.patientDoctorThread(patientId, _selectedDoctorEmail!))
        : state.caregiverPatientThread(patientId,
            caregiverEmail: _selectedCaregiverEmail);
    final selectedCaregiver = caregivers
        .where((caregiver) => caregiver.email == _selectedCaregiverEmail)
        .toList();
    final title = isDoctor
        ? (selectedDoctor == null
            ? 'Doctor'
            : state.doctorDisplayNameForAccount(selectedDoctor))
        : (selectedCaregiver.isEmpty ? 'Caregiver' : selectedCaregiver.first.name);
    final accent = isDoctor ? AppColors.indigo : AppColors.emerald;

    return Column(
      children: [
        PatientPageHeader(
          title: title,
          breadcrumb: 'Home > Messages',
          onBack: () => setState(() => _inThread = false),
          onHome: widget.onHome,
        ),
        Expanded(
          child: thread.isEmpty
              ? const EmptyState(icon: Icons.message, text: 'No messages yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: thread.length,
                  itemBuilder: (_, i) {
                    final m = thread[i];
                    return ChatBubble(
                      text: m.text,
                      time: m.time,
                      isSelf: m.role == Role.patient,
                      selfColor: accent,
                    );
                  },
                ),
        ),
        MessageInput(
          placeholder:
              isDoctor ? 'Message your doctor...' : 'Message your caregiver...',
          accentColor: accent,
          onSend: (text) {
            if (isDoctor) {
              final doctorEmail = _selectedDoctorEmail;
              if (patientId.isEmpty || doctorEmail == null) return;
              state.sendPatientMessage(
                patientId,
                text,
                state.patientFirstName,
                Role.patient,
                doctorEmail: doctorEmail,
              );
            } else {
              final caregiverEmail = _selectedCaregiverEmail;
              if (caregiverEmail == null) return;
              state.sendPatientCaregiverMessage(text, state.patientFirstName,
                  caregiverEmail: caregiverEmail);
            }
          },
        ),
      ],
    );
  }

  Widget _messageTile({
    IconData? icon,
    String? initials,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: icon != null
            ? Icon(icon, color: Colors.white)
            : Text(
                initials ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  String _patientThreadId(AppState state) {
    if (state.generatedPatientId.isNotEmpty) return state.generatedPatientId;
    if (state.selectedPatientId.isNotEmpty) return state.selectedPatientId;
    return state.selectedPatient?.id ?? '';
  }

  String _caregiverName(AppState state) {
    final patientId = _patientThreadId(state);
    for (final account in state.storedAccounts) {
      if (account.role == Role.caregiver &&
          account.linkedPatientId == patientId) {
        return account.name;
      }
    }
    return 'Caregiver';
  }

  String _lastPreview(List<ChatMessage> thread) {
    if (thread.isEmpty) return 'Tap to start a conversation';
    final last = thread.last;
    return last.role == Role.patient ? 'You: ${last.text}' : last.text;
  }

  String _initialsFor(String name, {required String fallback}) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? fallback : initials;
  }
}
