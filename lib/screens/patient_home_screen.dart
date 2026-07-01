import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/notifications/notification_service.dart';
import 'package:curome/widgets/common_widgets.dart';

enum _PatientTab { home, medicines, appointments, chatbot, messages }

enum _PtMsgTab { doctor, caregiver }

/// Parses "8:00 AM" / "20:00" style strings into minutes-from-midnight.
/// Returns -1 if it can't be parsed.
int _parseTimeToMinutes(String timeStr) {
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false)
      .firstMatch(timeStr);
  if (match == null) return -1;
  var h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final meridiem = (match.group(3) ?? '').toUpperCase();
  if (meridiem == 'PM' && h != 12) h += 12;
  if (meridiem == 'AM' && h == 12) h = 0;
  return h * 60 + m;
}

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  _PatientTab _tab = _PatientTab.home;
  bool _inThread = false;
  _PtMsgTab _msgTab = _PtMsgTab.doctor;

  bool _moodSubmitted = false;
  int? _selectedMood;
  bool _moodToastVisible = false;
  Timer? _moodToastTimer;

  String _chatNodeId = 'root';

  int? _sosCountdown;
  Timer? _sosTimer;
  bool _sosFired = false;

  String? _undoReminderId;
  final String _undoLabel = '';
  Timer? _undoTimer;

  @override
  void dispose() {
    _moodToastTimer?.cancel();
    _sosTimer?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _submitMood(int mood, AppState state) {
    state.submitMood(mood);
    setState(() {
      _selectedMood = mood;
      _moodSubmitted = true;
      _moodToastVisible = true;
    });
    _moodToastTimer?.cancel();
    _moodToastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _moodToastVisible = false);
    });
  }

  void _confirmReminder(String id, String label, AppState state) {
    state.takeMedicationReminder(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label marked as taken. Caregiver notified.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _undo(AppState state) {
    if (_undoReminderId == null) return;
    state.undoReminder(_undoReminderId!);
    setState(() => _undoReminderId = null);
  }

  void _startSos(AppState state) {
    setState(() {
      _sosCountdown = 5;
      _sosFired = false;
    });
    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final current = _sosCountdown ?? 0;
      if (current <= 1) {
        t.cancel();
        setState(() {
          _sosCountdown = null;
          _sosFired = true;
        });
        NotificationService.instance
            .sendSosAlert(state.session?.name ?? 'Patient');
        state.pushNotification(
            '${state.patientFirstName} has triggered an SOS request.',
            Role.caregiver);
        state.pushNotification(
            '${state.patientFirstName} has triggered an SOS request.',
            Role.doctor);
      } else {
        setState(() => _sosCountdown = current - 1);
      }
    });
  }

  void _cancelSos() {
    _sosTimer?.cancel();
    setState(() => _sosCountdown = null);
  }

  void _goHome() => setState(() {
        _tab = _PatientTab.home;
        _chatNodeId = 'root';
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final reminders = state.medicationReminders;
    Reminder? nextReminder;
    for (final r in reminders) {
      if (!r.confirmed) {
        nextReminder = r;
        break;
      }
    }
    final allDone = reminders.isNotEmpty && reminders.every((r) => r.confirmed);

    final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    AppointmentSlot? upcomingIn1h;
    for (final s in state.confirmedSlots) {
      final mins = _parseTimeToMinutes(s.time);
      if (mins == -1) continue;
      final diff = mins - nowMinutes;
      if (diff >= 0 && diff <= 60) {
        upcomingIn1h = s;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        children: [
          _buildTab(state, nextReminder, reminders, allDone, upcomingIn1h),
          if (!_moodSubmitted && state.shouldShowMoodCheck)
            _buildMoodModal(state),
          if (_moodToastVisible) _buildMoodToast(),
          if (_undoReminderId != null) _buildUndoToast(state),
          if (_sosCountdown != null) _buildSosCountdown(),
          if (_sosFired) _buildSosFired(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PatientBottomNav(
            active: _tab,
            onSelect: (t) => setState(() => _tab = t),
          ),
          _SOSButton(onTrigger: () => _startSos(state)),
        ],
      ),
    );
  }

  Widget _buildTab(
    AppState state,
    Reminder? nextReminder,
    List<Reminder> reminders,
    bool allDone,
    AppointmentSlot? upcomingIn1h,
  ) {
    switch (_tab) {
      case _PatientTab.home:
        return _homeTab(state, nextReminder, reminders, allDone, upcomingIn1h);
      case _PatientTab.medicines:
        return _medicinesTab(state, reminders);
      case _PatientTab.appointments:
        return _appointmentsTab(state);
      case _PatientTab.chatbot:
        return _chatbotTab();
      case _PatientTab.messages:
        return _messagesTab(state);
    }
  }

  // ── HOME ──
  Widget _homeTab(
    AppState state,
    Reminder? nextReminder,
    List<Reminder> reminders,
    bool allDone,
    AppointmentSlot? upcomingIn1h,
  ) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingIn1h != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminder: Your appointment is in less than 1 hour at ${upcomingIn1h.time}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              color: AppColors.purple,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Good morning,',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 15)),
                        Text(state.patientFirstName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(formatNow(),
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      state.logout();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (r) => false);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_moodSubmitted && _selectedMood != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.patientBorder),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOW YOU FEEL TODAY',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(moodIcon(_selectedMood!),
                                  size: 34, color: moodColors[_selectedMood!]),
                              const SizedBox(width: 10),
                              Text(moodLabels[_selectedMood!] ?? '',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.patientText)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  _medicineCard(state, nextReminder, reminders, allDone),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.medication,
                    iconColor: AppColors.patientAmber,
                    title: 'Take Medicine',
                    subtitle: reminders.isEmpty
                        ? 'No medications scheduled'
                        : reminders.where((r) => !r.confirmed).isNotEmpty
                            ? '${reminders.where((r) => !r.confirmed).length} medicine left today'
                            : 'All done for today',
                    onTap: () => setState(() => _tab = _PatientTab.medicines),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.calendar_month,
                    iconColor: AppColors.purple,
                    title: 'My Appointments',
                    subtitle: state.confirmedSlots.isNotEmpty
                        ? 'Next: ${state.confirmedSlots.first.date}'
                        : 'No visits coming up',
                    onTap: () =>
                        setState(() => _tab = _PatientTab.appointments),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.chat_bubble_outline,
                    iconColor: AppColors.teal,
                    title: 'Get Help',
                    subtitle: 'Questions? Talk to your helper',
                    onTap: () => setState(() => _tab = _PatientTab.chatbot),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.message,
                    iconColor: AppColors.indigo,
                    title: 'Messages',
                    subtitle: 'Talk to your doctor or caregiver',
                    onTap: () => setState(() {
                      _inThread = false;
                      _tab = _PatientTab.messages;
                    }),
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicineCard(AppState state, Reminder? nextReminder,
      List<Reminder> reminders, bool allDone) {
    if (reminders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.patientBg,
          border: Border.all(color: AppColors.patientBorder, width: 2),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.medication_outlined,
                size: 28, color: Colors.grey.shade300),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No medications scheduled.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
          ],
        ),
      );
    }
    if (nextReminder != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFD97706), width: 2),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text('Your next medicine, ${state.patientFirstName}:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF92400E))),
              ],
            ),
            const SizedBox(height: 10),
            Text(nextReminder.label,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.patientText)),
            Text(nextReminder.time,
                style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
            if (nextReminder.date.isNotEmpty)
              Text(nextReminder.date,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF777777))),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReminder(
                    nextReminder.id, nextReminder.label, state),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: Colors.green.shade600, width: 2),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 32, color: Colors.green.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All medicines taken!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
                Text('Great job today, ${state.patientFirstName}.',
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF555555))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.patientBorder, width: 2),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.patientText)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF666666))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── MEDICINES ──
  Widget _medicinesTab(AppState state, List<Reminder> reminders) {
    final allDone = reminders.isNotEmpty && reminders.every((r) => r.confirmed);
    return Column(
      children: [
        _PatientPageHeader(
          title: 'Take Medicine',
          breadcrumb: 'Home > Medicines',
          onBack: () => setState(() => _tab = _PatientTab.home),
          onHome: _goHome,
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
                          state, reminders[i], i, reminders.length),
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

  Widget _medicineStepCard(AppState state, Reminder r, int index, int total) {
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
                onPressed: () => _confirmReminder(r.id, r.label, state),
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

  // ── APPOINTMENTS (read-only) ──
  Widget _appointmentsTab(AppState state) {
    return Column(
      children: [
        _PatientPageHeader(
          title: 'My Appointments',
          breadcrumb: 'Home > Appointments',
          onBack: () => setState(() => _tab = _PatientTab.home),
          onHome: _goHome,
        ),
        Expanded(
          child: state.confirmedSlots.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 56, color: AppColors.purple),
                        const SizedBox(height: 12),
                        Text(
                          'No visits coming up. Your caregiver will let you know.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  itemCount: state.confirmedSlots.length,
                  itemBuilder: (_, i) {
                    final s = state.confirmedSlots[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: AppColors.patientBorder, width: 2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.calendar_month,
                                    color: AppColors.purple, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title ?? 'Appointment',
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.patientText)),
                                    Text(s.date,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF555555))),
                                    Text(s.time,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF555555))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'With Dr. ${state.doctorDisplayName.replaceFirst('Dr. ', '')}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B5CE7)),
                          ),
                          const Text(
                              'Your caregiver has arranged this for you.',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.notifications,
                                    color: AppColors.purple, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You will get a reminder before this visit',
                                    style: TextStyle(
                                        fontSize: 13, color: Color(0xFF5B21B6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── CHATBOT ──
  Widget _chatbotTab() {
    final node = chatTree[_chatNodeId] ?? chatTree['root']!;
    return Column(
      children: [
        _PatientPageHeader(
          title: 'Get Help',
          breadcrumb: 'Home > Help',
          onBack: _goHome,
          onHome: _goHome,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.patientBorder),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(node.text,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.patientText,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final opt in node.options.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      onTap: () => setState(() => _chatNodeId = opt.next),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 68),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFD97706), width: 2),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(_chatIcon(opt.label),
                                color: const Color(0xFFD97706)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(opt.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.patientText)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.settings, size: 18, color: Color(0xFF92400E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('This helper works without internet',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF92400E))),
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

  // Messages
  Widget _messagesTab(AppState state) {
    if (!_inThread) {
      return Column(
        children: [
          _PatientPageHeader(
            title: 'Messages',
            breadcrumb: 'Home > Messages',
            onBack: () => setState(() => _tab = _PatientTab.home),
            onHome: _goHome,
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
                    _msgTab = _PtMsgTab.doctor;
                    _inThread = true;
                  }),
                ),
                _messageTile(
                  initials: _initialsFor(_caregiverName(state), fallback: 'C'),
                  color: AppColors.emerald,
                  title: _caregiverName(state),
                  subtitle: _lastPreview(state.cgPatientThread),
                  onTap: () => setState(() {
                    _msgTab = _PtMsgTab.caregiver;
                    _inThread = true;
                  }),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final isDoctor = _msgTab == _PtMsgTab.doctor;
    final thread = isDoctor ? _doctorThread(state) : state.cgPatientThread;
    final title = isDoctor ? _doctorName(state) : _caregiverName(state);
    final accent = isDoctor ? AppColors.indigo : AppColors.emerald;

    return Column(
      children: [
        _PatientPageHeader(
          title: title,
          breadcrumb: 'Home > Messages',
          onBack: () => setState(() => _inThread = false),
          onHome: _goHome,
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

  IconData _chatIcon(String label) {
    switch (label) {
      case 'My medicine':
        return Icons.medication;
      case 'I feel upset':
        return Icons.favorite;
      case 'Call my caregiver':
        return Icons.phone;
      case 'Return Home':
      case 'Home':
        return Icons.home;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  // ── Overlays ──
  Widget _buildMoodModal(AppState state) {
    return Container(
      color: Colors.purple.shade900.withValues(alpha: 0.88),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.patientBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Good morning, ${state.patientFirstName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patientText)),
            const SizedBox(height: 6),
            const Text('How do you feel today?',
                style: TextStyle(fontSize: 17, color: Color(0xFF555555))),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in [
                  (
                    1,
                    'Very Sad',
                    Icons.sentiment_very_dissatisfied,
                    const Color(0xFF6B7280)
                  ),
                  (
                    2,
                    'Sad',
                    Icons.sentiment_dissatisfied,
                    const Color(0xFFD97706)
                  ),
                  (3, 'Okay', Icons.sentiment_neutral, const Color(0xFFCA8A04)),
                  (
                    4,
                    'Good',
                    Icons.sentiment_satisfied,
                    const Color(0xFF0D9488)
                  ),
                  (
                    5,
                    'Happy',
                    Icons.sentiment_very_satisfied,
                    const Color(0xFF16A34A)
                  ),
                ])
                  GestureDetector(
                    onTap: () => _submitMood(opt.$1, state),
                    child: Container(
                      width: 62,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.patientBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt.$3, color: opt.$4, size: 26),
                          const SizedBox(height: 4),
                          Text(opt.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Tap one to check in',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodToast() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  'Done! Well done, ${ref.read(appStateProvider).patientFirstName}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Colors.yellowAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUndoToast(AppState state) {
    return Positioned(
      bottom: 180,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$_undoLabel marked as taken',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
            TextButton(
              onPressed: () => _undo(state),
              child: const Text('Undo',
                  style: TextStyle(
                      color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosCountdown() {
    return Container(
      color: Colors.red.shade700,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 80),
          const SizedBox(height: 16),
          Text('SOS in ${_sosCountdown}s',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Calling emergency contact…',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _cancelSos,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSosFired() {
    return Container(
      color: Colors.red.shade800,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 80),
          const SizedBox(height: 16),
          const Text('Alert Sent',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text('Call and SMS dispatched to your emergency contact.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _sosFired = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            child: const Text('OK',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Local widgets (patient-only styling, dementia-friendly)
// ─────────────────────────────────────────────
class _PatientPageHeader extends StatelessWidget {
  final String title;
  final String breadcrumb;
  final VoidCallback onBack;
  final VoidCallback onHome;

  const _PatientPageHeader({
    required this.title,
    required this.breadcrumb,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.patientBg,
          border: Border(bottom: BorderSide(color: AppColors.patientBorder)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.patientText),
                  label: const Text('Back',
                      style: TextStyle(
                          color: AppColors.patientText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.patientText)),
                ),
                TextButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home, color: AppColors.patientText),
                  label: const Text('Home',
                      style: TextStyle(
                          color: AppColors.patientText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(breadcrumb,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.patientSubtext)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientBottomNav extends StatelessWidget {
  final _PatientTab active;
  final ValueChanged<_PatientTab> onSelect;

  const _PatientBottomNav({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_PatientTab.home, 'Home', Icons.home),
      (_PatientTab.medicines, 'Medicines', Icons.medication),
      (_PatientTab.appointments, 'Appointments', Icons.calendar_month),
      (_PatientTab.chatbot, 'Help', Icons.chat_bubble_outline),
      (_PatientTab.messages, 'Messages', Icons.message),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppColors.patientBorder, width: 2)),
      ),
      child: Row(
        children: tabs.map((t) {
          final selected = active == t.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(t.$1),
              child: Container(
                color: selected ? const Color(0xFFFFF8F0) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        color: selected
                            ? const Color(0xFFD97706)
                            : AppColors.patientSubtext),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                            color: selected
                                ? AppColors.patientText
                                : AppColors.patientSubtext)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SOSButton extends StatelessWidget {
  final VoidCallback onTrigger;
  const _SOSButton({required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      child: InkWell(
        onTap: onTrigger,
        child: Container(
          width: double.infinity,
          height: 72,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text('SOS — Get Help Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}
