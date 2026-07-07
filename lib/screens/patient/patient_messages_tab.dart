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
  ConsumerState<PatientMessagesTab> createState() =>
      _PatientMessagesTabState();
}

class _PatientMessagesTabState extends ConsumerState<PatientMessagesTab> {
  bool _inThread = false;
  PtMsgTab _msgTab = PtMsgTab.doctor;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

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
                _messageTile(
                  icon: Icons.medical_services,
                  color: AppColors.indigo,
                  title: _doctorName(state),
                  subtitle: _lastPreview(_doctorThread(state)),
                  onTap: () => setState(() {
                    _msgTab = PtMsgTab.doctor;
                    _inThread = true;
                  }),
                ),
                _messageTile(
                  initials: _initialsFor(_caregiverName(state), fallback: 'C'),
                  color: AppColors.emerald,
                  title: _caregiverName(state),
                  subtitle: _lastPreview(state.cgPatientThread),
                  onTap: () => setState(() {
                    _msgTab = PtMsgTab.caregiver;
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
    final thread = isDoctor ? _doctorThread(state) : state.cgPatientThread;
    final title = isDoctor ? _doctorName(state) : _caregiverName(state);
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
              final patientId = _patientThreadId(state);
              if (patientId.isEmpty) return;
              state.sendPatientMessage(
                patientId,
                text,
                state.patientFirstName,
                Role.patient,
              );
            } else {
              state.sendPatientCaregiverMessage(text, state.patientFirstName);
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

  List<ChatMessage> _doctorThread(AppState state) {
    final patientId = _patientThreadId(state);
    if (patientId.isEmpty) return const [];
    return state.patientMessages[patientId] ?? const [];
  }

  String _patientThreadId(AppState state) {
    if (state.generatedPatientId.isNotEmpty) return state.generatedPatientId;
    if (state.selectedPatientId.isNotEmpty) return state.selectedPatientId;
    return state.selectedPatient?.id ?? '';
  }

  String _doctorName(AppState state) {
    return state.linkedDoctorName.isEmpty ? 'Doctor' : state.linkedDoctorName;
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
