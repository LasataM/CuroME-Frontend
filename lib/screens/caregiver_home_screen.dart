import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/widgets/mood_chart.dart';

enum _CgTab { home, appointments, mood, visit, reminders, messages }

enum _CgMsgTab { doctor, patient }

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen> {
  _CgTab _tab = _CgTab.home;
  bool _showNotifications = false;

  // Appointments
  String? _suggestSlotId;
  final _suggestNoteCtrl = TextEditingController();
  String? _cancelSlotId;
  final _cancelReasonCtrl = TextEditingController();
  String? _doubleBookingWarningDate;

  // Visit notes
  final _noteCtrl = TextEditingController();

  // Reminders
  bool _showAddReminder = false;
  final _reminderLabelCtrl = TextEditingController();
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;

  // Messages
  _CgMsgTab _msgTab = _CgMsgTab.doctor;
  bool _inThread = false;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _suggestNoteCtrl.dispose();
    _cancelReasonCtrl.dispose();
    _noteCtrl.dispose();
    _reminderLabelCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  bool _checkDoubleBooking(AppState state, String patientId, String date) {
    return state.slots.any((s) =>
        s.patientId == patientId &&
        s.date == date &&
        (s.status == SlotStatus.confirmed ||
            s.status == SlotStatus.pendingDoctor));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) => t.format(context);

  DateTime _combineDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      backgroundColor: AppColors.greyBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildTab(state),
            if (_showNotifications) _notificationsOverlay(state),
            if (_doubleBookingWarningDate != null) _doubleBookingDialog(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildTab(AppState state) {
    switch (_tab) {
      case _CgTab.home:
        return _homeTab(state);
      case _CgTab.appointments:
        return _appointmentsTab(state);
      case _CgTab.mood:
        return _moodTab(state);
      case _CgTab.visit:
        return _visitTab(state);
      case _CgTab.reminders:
        return _remindersTab(state);
      case _CgTab.messages:
        return _messagesTab(state);
    }
  }

  Widget _bottomNav() {
    final tabs = [
      (_CgTab.home, 'Home', Icons.home),
      (_CgTab.appointments, 'Appts', Icons.calendar_month),
      (_CgTab.mood, 'Mood', Icons.trending_up),
      (_CgTab.reminders, 'Meds', Icons.medication),
      (_CgTab.visit, 'Visit', Icons.description),
      (_CgTab.messages, 'Messages', Icons.message),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: tabs.map((t) {
          final selected = _tab == t.$1;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _tab = t.$1;
                if (t.$1 != _CgTab.messages) _inThread = false;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        size: 22,
                        color: selected
                            ? AppColors.emerald
                            : Colors.grey.shade400),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? AppColors.emerald
                                : Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── HOME ──
  Widget _homeTab(AppState state) {
    final lastMood =
        state.moodHistory.isNotEmpty ? state.moodHistory.last : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            color: AppColors.emerald,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hello,',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(state.caregiverFirstName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(formatNow(),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                NotificationBell(
                  unreadCount: state.unreadCountFor(Role.caregiver),
                  onTap: () => setState(() => _showNotifications = true),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    state.logout();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (r) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.alertTriggered)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mood Alert',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Patient has had 3 consecutive sad check-ins. Please check in.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.slotsPendingCaregiver.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.amber.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${state.slotsPendingCaregiver.length} slot${state.slotsPendingCaregiver.length != 1 ? "s" : ""} awaiting your confirmation',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _tab = _CgTab.appointments),
                                child: Text('Review now',
                                    style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _quickCard(
                        'Appointments',
                        Icons.calendar_month,
                        AppColors.indigo,
                        () => setState(() => _tab = _CgTab.appointments)),
                    _quickCard(
                        'Mood Check-ins',
                        Icons.trending_up,
                        AppColors.purple,
                        () => setState(() => _tab = _CgTab.mood)),
                    _quickCard(
                        'Medicine',
                        Icons.medication,
                        Colors.blue.shade700,
                        () => setState(() => _tab = _CgTab.reminders)),
                    _quickCard(
                        'Visit Notes',
                        Icons.description,
                        Colors.amber.shade800,
                        () => setState(() => _tab = _CgTab.visit)),
                    _quickCard('Messages', Icons.message, AppColors.emerald,
                        () => setState(() => _tab = _CgTab.messages)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('LATEST MOOD CHECK-IN',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6),
                    ],
                  ),
                  child: lastMood == null
                      ? const Text('No check-in yet today.',
                          style: TextStyle(color: Colors.grey))
                      : Row(
                          children: [
                            MoodIcon(mood: lastMood.mood, size: 40),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lastMood.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(lastMood.date,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400)),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── APPOINTMENTS ──
  Widget _appointmentsTab(AppState state) {
    final myPending = state.slots
        .where((s) =>
            s.status == SlotStatus.pendingDoctor &&
            s.caregiverId == state.caregiverFirstName)
        .toList();
    final myCancellationRequests = state.slots
        .where((s) =>
            s.status == SlotStatus.pendingCancellation &&
            s.caregiverId == state.caregiverFirstName)
        .toList();

    return Column(
      children: [
        PageHeader(
          title: 'Appointments',
          onBack: () => setState(() => _tab = _CgTab.home),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.slotsPendingCaregiver.isNotEmpty) ...[
                _sectionLabel(
                    'Slots Awaiting Your Confirmation', Colors.amber.shade800),
                for (final s in state.slotsPendingCaregiver)
                  _slotCard(s, children: [
                    if (s.approvalNote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Doctor note: ${s.approvalNote}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.indigo)),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => state.confirmCaregiverSlot(s.id),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600),
                            child: const Text('Confirm',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _suggestSlotId = s.id),
                            child: const Text('Suggest Time'),
                          ),
                        ),
                      ],
                    ),
                  ]),
              ],
              _sectionLabel('Available to Book', Colors.grey.shade600),
              if (state.publishedAvailableSlots.isEmpty)
                const EmptyState(
                    icon: Icons.calendar_month,
                    text:
                        "No slots available. Your doctor hasn't published any yet.")
              else
                for (final s in state.publishedAvailableSlots)
                  _slotCard(s, children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final patientId = state.patients.isNotEmpty
                              ? state.patients.first.id
                              : '';
                          if (_checkDoubleBooking(state, patientId, s.date)) {
                            setState(() => _doubleBookingWarningDate = s.date);
                            return;
                          }
                          state.requestBooking(s.id);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigo),
                        icon: const Icon(Icons.calendar_month,
                            color: Colors.white),
                        label: const Text('Request Booking',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ]),
              if (myPending.isNotEmpty) ...[
                _sectionLabel('Pending Doctor Approval', AppColors.indigo),
                for (final s in myPending) _slotCard(s),
              ],
              if (myCancellationRequests.isNotEmpty) ...[
                _sectionLabel(
                    'Cancellation Approval Requests', Colors.orange.shade700),
                for (final s in myCancellationRequests) _slotCard(s),
              ],
              if (state.confirmedSlots.isNotEmpty) ...[
                _sectionLabel('Confirmed', Colors.green.shade700),
                for (final s in state.confirmedSlots)
                  _slotCard(s, children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _cancelSlotId = s.id),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red)),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ]),
              ],
              if (state.cancelledSlots.isNotEmpty) ...[
                _sectionLabel('Cancelled', Colors.red.shade400),
                for (final s in state.cancelledSlots)
                  Opacity(opacity: 0.75, child: _slotCard(s)),
              ],
            ],
          ),
        ),
        if (_suggestSlotId != null) _suggestTimeSheet(state),
        if (_cancelSlotId != null) _cancelSheet(state),
      ],
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1)),
      );

  Widget _slotCard(AppointmentSlot s, {List<Widget>? children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title ?? 'Appointment',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${s.date} at ${s.time} · ${s.duration}min',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    if (s.escalated)
                      const Text('Cancellation sent to doctor',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    if (s.cancelReason != null)
                      Text('Reason: ${s.cancelReason}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade400)),
                  ],
                ),
              ),
              StatusBadge(status: s.status),
            ],
          ),
          if (children != null) ...[
            const SizedBox(height: 10),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _suggestTimeSheet(AppState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Suggest Different Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                  'Leave a note for the doctor about your preferred time.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _suggestNoteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'e.g. Tuesday afternoon works better…',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _suggestSlotId = null;
                        _suggestNoteCtrl.clear();
                      }),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        state.suggestDifferentTime(
                            _suggestSlotId!, _suggestNoteCtrl.text);
                        setState(() {
                          _suggestSlotId = null;
                          _suggestNoteCtrl.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo),
                      child: const Text('Send Note',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancelSheet(AppState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancel Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _cancelReasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Reason for cancellation…',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Text(
                    'Note: Cancellations within 24 hours will be escalated to the doctor for approval.',
                    style: TextStyle(fontSize: 11, color: Colors.brown)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _cancelSlotId = null;
                        _cancelReasonCtrl.clear();
                      }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        state.cancelSlotCaregiver(
                            _cancelSlotId!,
                            _cancelReasonCtrl.text.isEmpty
                                ? 'No reason'
                                : _cancelReasonCtrl.text,
                            true);
                        setState(() {
                          _cancelSlotId = null;
                          _cancelReasonCtrl.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600),
                      child: const Text('Cancel Appointment',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doubleBookingDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 32),
              const SizedBox(height: 10),
              const Text('Already Booked',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                  'This patient already has an appointment on $_doubleBookingWarningDate. Please choose a different date.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _doubleBookingWarningDate = null),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo),
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MOOD ──
  Widget _moodTab(AppState state) {
    final recent = state.moodHistory.length > 7
        ? state.moodHistory.sublist(state.moodHistory.length - 7)
        : state.moodHistory;
    return Column(
      children: [
        PageHeader(
            title: 'Mood Check-ins',
            onBack: () => setState(() => _tab = _CgTab.home)),
        Expanded(
          child: state.moodHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.trending_up, text: 'No mood data yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    MoodAreaChart(data: recent, label: '7-Day Mood Timeline'),
                    const SizedBox(height: 16),
                    for (final entry in state.moodHistory.reversed)
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

  // ── VISIT NOTES ──
  Widget _visitTab(AppState state) {
    final patientId = state.linkedCaregiverPatientId;
    final notes = state.visitNotesForPatient(patientId).reversed.toList();

    return Column(
      children: [
        PageHeader(
            title: 'Visit Notes',
            onBack: () => setState(() => _tab = _CgTab.home)),
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

  // Medicine reminders
  Widget _remindersTab(AppState state) {
    final medicationReminders = state.medicationReminders;
    return Column(
      children: [
        PageHeader(
          title: 'Medicine',
          onBack: () => setState(() => _tab = _CgTab.home),
          action: IconButton(
            icon: Icon(_showAddReminder ? Icons.close : Icons.add,
                color: AppColors.indigo),
            onPressed: () =>
                setState(() => _showAddReminder = !_showAddReminder),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showAddReminder)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Medicine Reminder',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.indigo)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reminderLabelCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Medicine name',
                            filled: true,
                            fillColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _reminderDate = picked);
                                }
                              },
                              child: Text(_reminderDate == null
                                  ? 'Select date'
                                  : _fmtDate(_reminderDate!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now());
                                if (picked != null) {
                                  setState(() => _reminderTime = picked);
                                }
                              },
                              child: Text(_reminderTime == null
                                  ? 'Select time'
                                  : _fmtTime(_reminderTime!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                  'Patient and caregiver will be notified 5 minutes before the dose.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_reminderLabelCtrl.text.trim().isEmpty ||
                                _reminderDate == null ||
                                _reminderTime == null) {
                              return;
                            }
                            final dateStr = _fmtDate(_reminderDate!);
                            final timeStr = _fmtTime(_reminderTime!);
                            state.addMedicationReminder(
                              label: _reminderLabelCtrl.text.trim(),
                              date: dateStr,
                              time: timeStr,
                              dueAt: _combineDateTime(
                                  _reminderDate!, _reminderTime!),
                            );
                            _reminderLabelCtrl.clear();
                            setState(() {
                              _reminderDate = null;
                              _reminderTime = null;
                              _showAddReminder = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo),
                          child: const Text('Save Medicine Reminder',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              _sectionLabel('Medication Reminders', AppColors.indigo),
              if (medicationReminders.isEmpty)
                const EmptyState(
                    icon: Icons.medication, text: 'No medicines scheduled yet.')
              else
                for (final r in medicationReminders) _medicineReminderCard(r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medicineReminderCard(Reminder r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.medication, color: AppColors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${r.date.isEmpty ? "Today" : r.date} at ${r.time}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Reminder goes out 5 minutes before',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Pending',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade800)),
          ),
        ],
      ),
    );
  }

  // ── MESSAGES ──
  Widget _messagesTab(AppState state) {
    if (!_inThread) {
      return Column(
        children: [
          PageHeader(
              title: 'Messages',
              onBack: () => setState(() => _tab = _CgTab.home)),
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
                    _msgTab = _CgMsgTab.doctor;
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
                      _msgTab = _CgMsgTab.patient;
                      _inThread = true;
                    }),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final isDoctor = _msgTab == _CgMsgTab.doctor;
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

  Widget _notificationsOverlay(AppState state) {
    return GestureDetector(
      onTap: () {
        state.markNotificationsRead(Role.caregiver);
        setState(() => _showNotifications = false);
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            width: 300,
            height: 420,
            child: NotificationsPanel(
              notifications: state.notificationsFor(Role.caregiver),
              onClose: () {
                state.markNotificationsRead(Role.caregiver);
                setState(() => _showNotifications = false);
              },
            ),
          ),
        ),
      ),
    );
  }
}
