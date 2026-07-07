import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class CaregiverAppointmentsTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const CaregiverAppointmentsTab({super.key, required this.onBack});

  @override
  ConsumerState<CaregiverAppointmentsTab> createState() =>
      _CaregiverAppointmentsTabState();
}

class _CaregiverAppointmentsTabState
    extends ConsumerState<CaregiverAppointmentsTab> {
  String? _suggestSlotId;
  final _suggestNoteCtrl = TextEditingController();
  String? _cancelSlotId;
  final _cancelReasonCtrl = TextEditingController();
  String? _doubleBookingWarningDate;

  @override
  void dispose() {
    _suggestNoteCtrl.dispose();
    _cancelReasonCtrl.dispose();
    super.dispose();
  }

  bool _checkDoubleBooking(AppState state, String patientId, String date) {
    return state.slots.any((s) =>
        s.patientId == patientId &&
        s.date == date &&
        (s.status == SlotStatus.confirmed ||
            s.status == SlotStatus.pendingDoctor));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Stack(
      children: [
        _appointmentsTab(state),
        if (_suggestSlotId != null) _suggestTimeSheet(state),
        if (_cancelSlotId != null) _cancelSheet(state),
        if (_doubleBookingWarningDate != null) _doubleBookingDialog(),
      ],
    );
  }

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
          onBack: widget.onBack,
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
                  Opacity(opacity: 0.75, child: _slotCard(s, state: state)),
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

  Widget _slotCard(AppointmentSlot s,
      {List<Widget>? children, AppState? state}) {
    final cancellationSource = state?.cancellationSourceLabel(s) ?? '';
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
}
