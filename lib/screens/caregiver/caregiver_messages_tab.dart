import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/caregiver/caregiver_tab.dart';

class CaregiverMessagesTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const CaregiverMessagesTab({super.key, required this.onBack});

  @override
  ConsumerState<CaregiverMessagesTab> createState() =>
      _CaregiverMessagesTabState();
}

class _CaregiverMessagesTabState extends ConsumerState<CaregiverMessagesTab> {
  CaregiverMsgTab _msgTab = CaregiverMsgTab.doctor;
  bool _inThread = false;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    if (!_inThread) {
      return Column(
        children: [
          PageHeader(title: 'Messages', onBack: widget.onBack),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: AppColors.indigo,
                      child: Icon(Icons.medical_services, color: Colors.white)),
                  title: Text(
                      state.linkedDoctorName.isEmpty
                          ? 'Doctor'
                          : state.linkedDoctorName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      state.caregiverDoctorThread.isNotEmpty
                          ? state.caregiverDoctorThread.last.text
                          : 'Tap to start a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () => setState(() {
                    _msgTab = CaregiverMsgTab.doctor;
                    _inThread = true;
                  }),
                ),
                if (state.linkedPatientName.isNotEmpty ||
                    state.cgPatientThread.isNotEmpty)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.purple,
                      child: Text(
                          state.linkedPatientName.isNotEmpty
                              ? state.linkedPatientName
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .map((n) => n[0])
                                  .take(2)
                                  .join()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                    title: Text(
                        state.linkedPatientName.isEmpty
                            ? 'Patient'
                            : state.linkedPatientName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        state.cgPatientThread.isNotEmpty
                            ? state.cgPatientThread.last.text
                            : 'Tap to start a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => setState(() {
                      _msgTab = CaregiverMsgTab.patient;
                      _inThread = true;
                    }),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final isDoctor = _msgTab == CaregiverMsgTab.doctor;
    final thread =
        isDoctor ? state.caregiverDoctorThread : state.cgPatientThread;
    return Column(
      children: [
        PageHeader(
          title: isDoctor
              ? (state.linkedDoctorName.isEmpty
                  ? 'Doctor'
                  : state.linkedDoctorName)
              : (state.linkedPatientName.isEmpty
                  ? 'Patient'
                  : state.linkedPatientName),
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
                        isSelf: m.role == Role.caregiver,
                        selfColor: AppColors.emerald);
                  },
                ),
        ),
        MessageInput(
          placeholder:
              isDoctor ? 'Message your doctor…' : 'Message your patient…',
          accentColor: AppColors.emerald,
          onSend: (text) {
            if (isDoctor) {
              state.sendCgDoctorMessage(text, state.caregiverFirstName);
            } else {
              state.sendCgPatientMessage(text, state.caregiverFirstName);
            }
          },
        ),
      ],
    );
  }
}
