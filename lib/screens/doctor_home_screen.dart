import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/widgets/mood_chart.dart';

enum _DoctorTab { home, appointments, mood, suggestions, messages }

enum _DoctorMsgInbox { patient, caregiver }

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  _DoctorTab _tab = _DoctorTab.home;
  bool _showNotifications = false;

  // Home / general
  String _moodPatientId = '';

  // Appointments
  bool _showAddSlot = false;
  final _slotTitleCtrl = TextEditingController();
  DateTime? _slotDate;
  TimeOfDay? _slotTime;
  int _slotDuration = 30;
  String _slotFollowUp = 'one-time';
  bool _slotConflict = false;
  final _declineReasonCtrl = TextEditingController();
  String? _decliningSlotId;
  final _cancelReasonCtrl = TextEditingController();
  String? _cancellingSlotId;
  String? _modifyingSlotId;
  DateTime? _modifyDate;
  TimeOfDay? _modifyTime;

  // Suggestions
  bool _showAddSugg = false;
  String _suggType = 'activity';
  Priority _suggPriority = Priority.medium;
  final _suggTextCtrl = TextEditingController();
  final _suggRationaleCtrl = TextEditingController();

  // Messages
  _DoctorMsgInbox _inboxTab = _DoctorMsgInbox.patient;
  bool _inThread = false;
  String? _selectedCgId;

  @override
  void dispose() {
    _slotTitleCtrl.dispose();
    _declineReasonCtrl.dispose();
    _cancelReasonCtrl.dispose();
    _suggTextCtrl.dispose();
    _suggRationaleCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    if (_moodPatientId.isEmpty && state.patients.isNotEmpty) {
      _moodPatientId = state.selectedPatientId.isNotEmpty
          ? state.selectedPatientId
          : state.patients.first.id;
    }

    return Scaffold(
      backgroundColor: AppColors.greyBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildTab(state),
            if (_showNotifications) _notificationsOverlay(state),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildTab(AppState state) {
    switch (_tab) {
      case _DoctorTab.home:
        return _homeTab(state);
      case _DoctorTab.appointments:
        return _appointmentsTab(state);
      case _DoctorTab.mood:
        return _moodTab(state);
      case _DoctorTab.suggestions:
        return _suggestionsTab(state);
      case _DoctorTab.messages:
        return _messagesTab(state);
    }
  }

  Widget _bottomNav() {
    final tabs = [
      (_DoctorTab.home, 'Home', Icons.home),
      (_DoctorTab.appointments, 'Slots', Icons.calendar_month),
      (_DoctorTab.mood, 'Mood', Icons.trending_up),
      (_DoctorTab.suggestions, 'Suggest', Icons.medication),
      (_DoctorTab.messages, 'Messages', Icons.message),
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
                if (t.$1 != _DoctorTab.messages) _inThread = false;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        size: 22,
                        color: selected ? AppColors.indigo : Colors.grey.shade400),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color:
                                selected ? AppColors.indigo : Colors.grey.shade400)),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            color: AppColors.indigo,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good morning,',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(state.doctorDisplayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(formatNow(),
                          style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                NotificationBell(
                  unreadCount: state.unreadCountFor(Role.doctor),
                  onTap: () => setState(() => _showNotifications = true),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    state.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          PatientSelector(
            patients: state.patients,
            selectedId: state.selectedPatientId,
            onSelect: (id) => state.selectedPatientId = id,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _quickCard('Appointments', Icons.calendar_month, AppColors.indigo,
                    () => setState(() => _tab = _DoctorTab.appointments)),
                _quickCard('Mood Trends', Icons.trending_up, AppColors.purple,
                    () => setState(() => _tab = _DoctorTab.mood)),
                _quickCard('Suggestions', Icons.medication, Colors.green.shade700,
                    () => setState(() => _tab = _DoctorTab.suggestions)),
                _quickCard('Messages', Icons.message, Colors.blue.shade700,
                    () => setState(() => _tab = _DoctorTab.messages)),
              ],
            ),
          ),
          if (state.alertTriggered && state.selectedPatient != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _alertBanner(
                  'Mood Alert — ${state.selectedPatient!.name}',
                  'Patient recorded 3+ consecutive sad check-ins.',
                  Colors.red),
            ),
          if (state.awaitingApprovalSlots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: AppColors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${state.awaitingApprovalSlots.length} booking request${state.awaitingApprovalSlots.length != 1 ? "s" : ""} awaiting approval',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.indigo,
                                  fontSize: 13)),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _tab = _DoctorTab.appointments),
                            child: const Text('Review now',
                                style: TextStyle(
                                    color: AppColors.indigo,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickCard(String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _alertBanner(String title, String subtitle, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade200),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color.shade500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                        fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(color: color.shade600, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── APPOINTMENTS ──
  Widget _appointmentsTab(AppState state) {
    final available = state.slots.where((s) => s.status == SlotStatus.available).toList();
    final cancelled = state.slots.where((s) => s.status == SlotStatus.cancelled).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Appointment Slots',
          onBack: () => setState(() => _tab = _DoctorTab.home),
          action: IconButton(
            icon: Icon(_showAddSlot ? Icons.close : Icons.add,
                color: AppColors.indigo),
            onPressed: () => setState(() => _showAddSlot = !_showAddSlot),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showAddSlot) _addSlotForm(state),
              if (state.awaitingApprovalSlots.isNotEmpty) ...[
                _sectionLabel('Awaiting Approval', AppColors.indigo),
                for (final s in state.awaitingApprovalSlots)
                  _slotCard(state, s, actions: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => state.approveSlot(s.id),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600),
                        icon: const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        label: const Text('Approve',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _decliningSlotId = s.id),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red)),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Decline'),
                      ),
                    ),
                  ]),
              ],
              if (state.confirmedSlots.isNotEmpty) ...[
                _sectionLabel('Confirmed', Colors.green.shade700),
                for (final s in state.confirmedSlots)
                  _slotCard(state, s, actions: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _modifyingSlotId = s.id;
                        }),
                        child: const Text('Modify'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red)),
                        onPressed: () => setState(() => _cancellingSlotId = s.id),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ]),
              ],
              _sectionLabel('Available Slots', Colors.grey.shade600),
              if (available.isEmpty)
                const EmptyState(
                    icon: Icons.calendar_month,
                    text: 'No available slots. Tap + to create one.')
              else
                for (final s in available)
                  _slotCard(state, s, trailingPublish: true),
              if (cancelled.isNotEmpty) ...[
                _sectionLabel('Cancelled', Colors.red.shade300),
                for (final s in cancelled)
                  Opacity(opacity: 0.6, child: _slotCard(state, s)),
              ],
            ],
          ),
        ),
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

  Widget _addSlotForm(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Appointment Slot',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.indigo)),
          const SizedBox(height: 10),
          TextField(
            controller: _slotTitleCtrl,
            decoration: const InputDecoration(
                hintText: 'Title (optional)', filled: true, fillColor: Colors.white),
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _slotDate = picked;
                        _slotConflict = false;
                      });
                    }
                  },
                  child: Text(_slotDate == null ? 'Select date' : _fmtDate(_slotDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (picked != null) {
                      setState(() {
                        _slotTime = picked;
                        _slotConflict = false;
                      });
                    }
                  },
                  child: Text(_slotTime == null ? 'Select time' : _fmtTime(_slotTime!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Duration (minutes)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [15, 30, 45, 60].map((d) {
              final sel = _slotDuration == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${d}m'),
                    selected: sel,
                    onSelected: (_) => setState(() => _slotDuration = d),
                    selectedColor: AppColors.indigo,
                    labelStyle:
                        TextStyle(color: sel ? Colors.white : Colors.black87),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text('Follow-up Schedule',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: ['one-time', 'weekly', 'fortnightly', 'monthly'].map((opt) {
              final sel = _slotFollowUp == opt;
              return ChoiceChip(
                label: Text(opt == 'one-time'
                    ? 'One-time'
                    : opt[0].toUpperCase() + opt.substring(1)),
                selected: sel,
                onSelected: (_) => setState(() => _slotFollowUp = opt),
                selectedColor: AppColors.indigo,
                labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
              );
            }).toList(),
          ),
          if (_slotConflict)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Text(
                    'Conflict: another appointment exists at this time.',
                    style: TextStyle(color: Colors.amber, fontSize: 12)),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_slotDate == null || _slotTime == null) return;
                final dateStr = _fmtDate(_slotDate!);
                final timeStr = _fmtTime(_slotTime!);
                if (state.checkConflict(dateStr, timeStr)) {
                  setState(() => _slotConflict = true);
                  return;
                }
                state.addSlot(
                  date: dateStr,
                  time: timeStr,
                  duration: _slotDuration,
                  title: _slotTitleCtrl.text,
                  followUp: _slotFollowUp == 'one-time'
                      ? null
                      : FollowUpSchedule.values
                          .firstWhere((f) => f.name == _slotFollowUp),
                );
                setState(() {
                  _showAddSlot = false;
                  _slotTitleCtrl.clear();
                  _slotDate = null;
                  _slotTime = null;
                  _slotDuration = 30;
                  _slotFollowUp = 'one-time';
                  _slotConflict = false;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Create Slot', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(AppState state, AppointmentSlot s,
      {List<Widget>? actions, bool trailingPublish = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
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
                    if (s.caregiverId != null)
                      Text('Requested by: ${s.caregiverId}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.indigo)),
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
          if (trailingPublish) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => state.togglePublish(s.id),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        s.published ? Colors.green.shade100 : AppColors.indigo,
                  ),
                  child: Text(s.published ? 'Unpublish' : 'Publish',
                      style: TextStyle(
                          color: s.published
                              ? Colors.green.shade700
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const Spacer(),
                _viewLogButton(s),
              ],
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 10),
            Row(children: actions),
            const SizedBox(height: 6),
            _viewLogButton(s),
          ],
          if (actions == null && !trailingPublish) ...[
            const SizedBox(height: 6),
            _viewLogButton(s),
          ],
        ],
      ),
    );
  }

  Widget _viewLogButton(AppointmentSlot s) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => AuditLogSheet(log: s.log),
      ),
      child: const Text('View Log',
          style: TextStyle(
              fontSize: 11, color: AppColors.indigo, decoration: TextDecoration.underline)),
    );
  }

  // ── MOOD ──
  Widget _moodTab(AppState state) {
    final patient = state.patients.where((p) => p.id == _moodPatientId).isEmpty
        ? (state.patients.isNotEmpty ? state.patients.first : null)
        : state.patients.firstWhere((p) => p.id == _moodPatientId);
    final data = state.patientMoodData[_moodPatientId] ?? [];

    return Column(
      children: [
        PageHeader(
          title: 'Mood Trends',
          onBack: () => setState(() => _tab = _DoctorTab.home),
        ),
        if (state.patients.isNotEmpty)
          PatientSelector(
            patients: state.patients,
            selectedId: _moodPatientId,
            onSelect: (id) => setState(() => _moodPatientId = id),
          ),
        Expanded(
          child: patient == null
              ? const EmptyState(icon: Icons.person, text: 'No patients yet.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        PatientAvatar(patient: patient, size: 36),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const Text('7-day mood history',
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MoodAreaChart(
                        data: data, label: 'Mood Score (1 = Very Sad · 5 = Very Happy)'),
                    const SizedBox(height: 16),
                    const Text('CHECK-IN HISTORY',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (data.isEmpty)
                      const EmptyState(icon: Icons.trending_up, text: 'No mood data yet.')
                    else
                      for (final entry in data.reversed.take(7))
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
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
                                        style:
                                            const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(entry.date,
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey.shade400)),
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

  // ── SUGGESTIONS ──
  Widget _suggestionsTab(AppState state) {
    final patient = state.selectedPatient;
    final current =
        state.suggestions.where((s) => s.patientId == state.selectedPatientId).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Suggestions',
          onBack: () => setState(() => _tab = _DoctorTab.home),
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
                                style:
                                    const TextStyle(fontSize: 11, color: Colors.grey)),
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
                labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
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
                labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _suggTextCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Recommendation…', filled: true, fillColor: Colors.white),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(s.type, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const Spacer(),
              PriorityBadge(priority: s.priority),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(s.rationale, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ── MESSAGES ──
  Widget _messagesTab(AppState state) {
    if (!_inThread) {
      return Column(
        children: [
          PageHeader(title: 'Messages', onBack: () => setState(() => _tab = _DoctorTab.home)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _inboxTabButton('Patient Inbox', _DoctorMsgInbox.patient,
                      AppColors.indigo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _inboxTabButton('Caregiver Inbox', _DoctorMsgInbox.caregiver,
                      AppColors.teal),
                ),
              ],
            ),
          ),
          Expanded(
            child: _inboxTab == _DoctorMsgInbox.patient
                ? _patientInboxList(state)
                : _caregiverInboxList(state),
          ),
        ],
      );
    }
    return _inboxTab == _DoctorMsgInbox.patient
        ? _patientThread(state)
        : _caregiverThread(state);
  }

  Widget _inboxTabButton(String label, _DoctorMsgInbox tab, Color color) {
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
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) {
        final p = state.patients[i];
        final msgs = state.patientMessages[p.id] ?? [];
        final last = msgs.isNotEmpty ? msgs.last : null;
        return ListTile(
          leading: PatientAvatar(patient: p, size: 44),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              last == null ? 'No messages yet' : (last.role == Role.doctor ? 'You: ${last.text}' : last.text),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: last != null ? Text(last.time, style: const TextStyle(fontSize: 11)) : null,
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
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
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
          title: Text(cg.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Caregiver · ${cg.patientName}',
              style: const TextStyle(fontSize: 11)),
          trailing: last != null ? Text(last.time, style: const TextStyle(fontSize: 11)) : null,
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
    final cg = state.caregiverContacts
        .where((c) => c.id == _selectedCgId)
        .isEmpty
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

  Widget _notificationsOverlay(AppState state) {
    return GestureDetector(
      onTap: () {
        state.markNotificationsRead(Role.doctor);
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
              notifications: state.notificationsFor(Role.doctor),
              onClose: () {
                state.markNotificationsRead(Role.doctor);
                setState(() => _showNotifications = false);
              },
            ),
          ),
        ),
      ),
    );
  }
}