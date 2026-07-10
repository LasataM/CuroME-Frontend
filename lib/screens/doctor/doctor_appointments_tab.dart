import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class DoctorAppointmentsTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DoctorAppointmentsTab({super.key, required this.onBack});

  @override
  ConsumerState<DoctorAppointmentsTab> createState() =>
      _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState
    extends ConsumerState<DoctorAppointmentsTab> {
  bool _showAddSlot = false;
  final _slotTitleCtrl = TextEditingController();
  DateTime? _slotDate;
  TimeOfDay? _slotTime;
  int _slotDuration = 30;
  String _slotFollowUp = 'one-time';
  bool _slotConflict = false;
  final _declineReasonCtrl = TextEditingController();
  String? _decliningSlotId;
  String? _decliningCancellationSlotId;
  final _cancelReasonCtrl = TextEditingController();
  String? _cancellingSlotId;
  String? _modifyingSlotId;
  DateTime? _modifyDate;
  TimeOfDay? _modifyTime;

  @override
  void dispose() {
    _slotTitleCtrl.dispose();
    _declineReasonCtrl.dispose();
    _cancelReasonCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return _appointmentsTab(state);
  }

  Widget _appointmentsTab(AppState state) {
    final visibleSlots = state.doctorScopedSlots;
    final available =
        visibleSlots.where((s) => s.status == SlotStatus.available).toList();
    final cancelled =
        visibleSlots.where((s) => s.status == SlotStatus.cancelled).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Appointment Slots',
          onBack: widget.onBack,
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
              if (state.cancellationApprovalSlots.isNotEmpty) ...[
                _sectionLabel(
                    'Cancellation Approval Requests', Colors.orange.shade700),
                for (final s in state.cancellationApprovalSlots)
                  _slotCard(state, s,
                      requestLabel: 'Cancellation requested by',
                      actions: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                state.approveCancellationRequest(s.id),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700),
                            icon: const Icon(Icons.event_busy,
                                color: Colors.white, size: 16),
                            label: const Text('Approve Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(
                                () => _decliningCancellationSlotId = s.id),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red)),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Decline'),
                          ),
                        ),
                      ]),
              ],
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
                        onPressed: () =>
                            setState(() => _decliningSlotId = s.id),
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
                        onPressed: () =>
                            setState(() => _cancellingSlotId = s.id),
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
        if (_decliningSlotId != null) _declineSheet(state),
        if (_decliningCancellationSlotId != null) _declineSheet(state),
        if (_cancellingSlotId != null) _doctorCancelSheet(state),
        if (_modifyingSlotId != null) _modifySheet(state),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.indigo)),
          const SizedBox(height: 10),
          TextField(
            controller: _slotTitleCtrl,
            decoration: const InputDecoration(
                hintText: 'Title (optional)',
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _slotDate = picked;
                        _slotConflict = false;
                      });
                    }
                  },
                  child: Text(
                      _slotDate == null ? 'Select date' : _fmtDate(_slotDate!)),
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
                  child: Text(
                      _slotTime == null ? 'Select time' : _fmtTime(_slotTime!)),
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
            children:
                ['one-time', 'weekly', 'fortnightly', 'monthly'].map((opt) {
              final sel = _slotFollowUp == opt;
              return ChoiceChip(
                label: Text(opt == 'one-time'
                    ? 'One-time'
                    : opt[0].toUpperCase() + opt.substring(1)),
                selected: sel,
                onSelected: (_) => setState(() => _slotFollowUp = opt),
                selectedColor: AppColors.indigo,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : Colors.black87),
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Create Slot',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(AppState state, AppointmentSlot s,
      {List<Widget>? actions,
      bool trailingPublish = false,
      String requestLabel = 'Requested by'}) {
    final cancellationSource = state.cancellationSourceLabel(s);
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
                    if (s.caregiverId != null)
                      Text('$requestLabel: ${s.caregiverId}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.indigo)),
                    if (cancellationSource.isNotEmpty)
                      Text(cancellationSource,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600)),
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
              fontSize: 11,
              color: AppColors.indigo,
              decoration: TextDecoration.underline)),
    );
  }

  Widget _declineSheet(AppState state) {
    final isCancellationDecline = _decliningCancellationSlotId != null;
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
              Text(
                  isCancellationDecline
                      ? 'Decline Cancellation Request'
                      : 'Decline Booking Request',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _declineReasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for declining...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _decliningSlotId = null;
                        _decliningCancellationSlotId = null;
                        _declineReasonCtrl.clear();
                      }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final reason = _declineReasonCtrl.text.trim().isEmpty
                            ? 'No reason provided.'
                            : _declineReasonCtrl.text.trim();
                        if (isCancellationDecline) {
                          state.declineCancellationRequest(
                              _decliningCancellationSlotId!, reason);
                        } else {
                          state.declineSlot(_decliningSlotId!, reason);
                        }
                        setState(() {
                          _decliningSlotId = null;
                          _decliningCancellationSlotId = null;
                          _declineReasonCtrl.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600),
                      child: const Text('Decline',
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

  Widget _doctorCancelSheet(AppState state) {
    final hasReason = _cancelReasonCtrl.text.trim().isNotEmpty;
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
              const Text('Cancel Accepted Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('A valid reason is required before cancelling.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _cancelReasonCtrl,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Reason for cancellation...',
                  border: const OutlineInputBorder(),
                  errorText: hasReason ? null : 'Reason is required',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _cancellingSlotId = null;
                        _cancelReasonCtrl.clear();
                      }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasReason
                          ? () {
                              state.cancelSlotDoctor(_cancellingSlotId!,
                                  _cancelReasonCtrl.text.trim());
                              setState(() {
                                _cancellingSlotId = null;
                                _cancelReasonCtrl.clear();
                              });
                            }
                          : null,
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

  Widget _modifySheet(AppState state) {
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
              const Text('Modify Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _modifyDate = picked);
                        }
                      },
                      child: Text(_modifyDate == null
                          ? 'Select date'
                          : _fmtDate(_modifyDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          setState(() => _modifyTime = picked);
                        }
                      },
                      child: Text(_modifyTime == null
                          ? 'Select time'
                          : _fmtTime(_modifyTime!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _modifyingSlotId = null;
                        _modifyDate = null;
                        _modifyTime = null;
                      }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _modifyDate == null || _modifyTime == null
                          ? null
                          : () {
                              state.modifySlot(
                                  _modifyingSlotId!,
                                  _fmtDate(_modifyDate!),
                                  _fmtTime(_modifyTime!));
                              setState(() {
                                _modifyingSlotId = null;
                                _modifyDate = null;
                                _modifyTime = null;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo),
                      child: const Text('Save Changes',
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
}
