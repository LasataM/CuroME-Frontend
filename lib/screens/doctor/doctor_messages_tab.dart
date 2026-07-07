import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/doctor/doctor_tab.dart';

class DoctorMessagesTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DoctorMessagesTab({super.key, required this.onBack});

  @override
  ConsumerState<DoctorMessagesTab> createState() => _DoctorMessagesTabState();
}

class _DoctorMessagesTabState extends ConsumerState<DoctorMessagesTab> {
  DoctorMsgInbox _inboxTab = DoctorMsgInbox.patient;
  bool _inThread = false;
  String? _selectedCgId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return _messagesTab(state);
  }

  Widget _messagesTab(AppState state) {
    if (!_inThread) {
      return Column(
        children: [
          PageHeader(title: 'Messages', onBack: widget.onBack),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _inboxTabButton('Patient Inbox',
                      DoctorMsgInbox.patient, AppColors.indigo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _inboxTabButton('Caregiver Inbox',
                      DoctorMsgInbox.caregiver, AppColors.teal),
                ),
              ],
            ),
          ),
          Expanded(
            child: _inboxTab == DoctorMsgInbox.patient
                ? _patientInboxList(state)
                : _caregiverInboxList(state),
          ),
        ],
      );
    }
    return _inboxTab == DoctorMsgInbox.patient
        ? _patientThread(state)
        : _caregiverThread(state);
  }

  Widget _inboxTabButton(String label, DoctorMsgInbox tab, Color color) {
    final sel = _inboxTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _inboxTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _patientInboxList(AppState state) {
    if (state.patients.isEmpty) {
      return const EmptyState(icon: Icons.message, text: 'No messages yet.');
    }
    return ListView.separated(
      itemCount: state.patients.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) {
        final p = state.patients[i];
        final msgs = state.patientMessages[p.id] ?? [];
        final last = msgs.isNotEmpty ? msgs.last : null;
        return ListTile(
          leading: PatientAvatar(patient: p, size: 44),
          title:
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              last == null
                  ? 'No messages yet'
                  : (last.role == Role.doctor
                      ? 'You: ${last.text}'
                      : last.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: last != null
              ? Text(last.time, style: const TextStyle(fontSize: 11))
              : null,
          onTap: () => setState(() {
            state.selectedPatientId = p.id;
            _inThread = true;
          }),
        );
      },
    );
  }

  Widget _caregiverInboxList(AppState state) {
    if (state.caregiverContacts.isEmpty) {
      return const EmptyState(icon: Icons.message, text: 'No messages yet.');
    }
    return ListView.separated(
      itemCount: state.caregiverContacts.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) {
        final cg = state.caregiverContacts[i];
        final thread = state.docCgThreads[cg.id] ?? [];
        final last = thread.isNotEmpty ? thread.last : null;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(cg.avatarColor),
            child: Text(cg.initials,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          title: Text(cg.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Caregiver · ${cg.patientName}',
              style: const TextStyle(fontSize: 11)),
          trailing: last != null
              ? Text(last.time, style: const TextStyle(fontSize: 11))
              : null,
          onTap: () => setState(() {
            _selectedCgId = cg.id;
            _inThread = true;
          }),
        );
      },
    );
  }

  Widget _patientThread(AppState state) {
    final patient = state.selectedPatient;
    final msgs = state.patientMessages[state.selectedPatientId] ?? [];
    return Column(
      children: [
        PageHeader(
          title: patient != null ? 'Chat with ${patient.shortName}' : 'Chat',
          onBack: () => setState(() => _inThread = false),
        ),
        Expanded(
          child: msgs.isEmpty
              ? const EmptyState(icon: Icons.message, text: 'No messages yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    return ChatBubble(
                        text: m.text,
                        time: m.time,
                        isSelf: m.role == Role.doctor,
                        selfColor: AppColors.indigo);
                  },
                ),
        ),
        if (patient != null)
          MessageInput(
            placeholder: 'Message ${patient.shortName}…',
            accentColor: AppColors.indigo,
            onSend: (text) => state.sendPatientMessage(
                patient.id, text, state.doctorDisplayName, Role.doctor),
          ),
      ],
    );
  }

  Widget _caregiverThread(AppState state) {
    final cg =
        state.caregiverContacts.where((c) => c.id == _selectedCgId).isEmpty
            ? null
            : state.caregiverContacts.firstWhere((c) => c.id == _selectedCgId);
    final thread = state.docCgThreads[_selectedCgId] ?? [];
    return Column(
      children: [
        PageHeader(
          title: cg != null ? 'Chat with ${cg.shortName}' : 'Chat',
          onBack: () => setState(() => _inThread = false),
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
                        isSelf: m.role == Role.doctor,
                        selfColor: AppColors.teal);
                  },
                ),
        ),
        if (cg != null)
          MessageInput(
            placeholder: 'Message ${cg.shortName}…',
            accentColor: AppColors.teal,
            onSend: (text) =>
                state.sendDocCgMessage(cg.id, text, state.doctorDisplayName),
          ),
      ],
    );
  }
}
