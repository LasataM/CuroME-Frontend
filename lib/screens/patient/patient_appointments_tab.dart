import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/screens/patient/patient_widgets.dart';

class PatientAppointmentsTab extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const PatientAppointmentsTab(
      {super.key, required this.onBack, required this.onHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final appointments = [
      ...state.confirmedSlots,
      ...state.cancelledSlots,
    ];
    final appointmentsByDoctor = state.slotsByDoctor(appointments);

    return Column(
      children: [
        PatientPageHeader(
          title: 'My Appointments',
          breadcrumb: 'Home > Appointments',
          onBack: onBack,
          onHome: onHome,
        ),
        Expanded(
          child: appointments.isEmpty
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  children: [
                    for (final entry in appointmentsByDoctor.entries) ...[
                      _doctorSubLabel(
                          state.doctorDisplayNameForEmail(entry.key)),
                      for (final s in entry.value) _appointmentCard(state, s),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _doctorSubLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            const Icon(Icons.medical_services,
                size: 16, color: AppColors.purple),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple)),
          ],
        ),
      );

  Widget _appointmentCard(AppState state, AppointmentSlot s) {
    final cancelled = s.status == SlotStatus.cancelled;
    final doctorName = state.doctorDisplayNameForEmail(s.doctorId);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: cancelled ? Colors.red.shade200 : AppColors.patientBorder,
            width: 2),
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
                  color:
                      cancelled ? Colors.red.shade50 : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(cancelled ? Icons.event_busy : Icons.calendar_month,
                    color: cancelled ? Colors.red : AppColors.purple, size: 28),
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
                            fontSize: 15, color: Color(0xFF555555))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'With $doctorName',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B5CE7)),
          ),
          const Text('Your caregiver has arranged this for you.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cancelled ? Colors.red.shade50 : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Row(
              children: [
                Icon(cancelled ? Icons.cancel : Icons.notifications,
                    color: cancelled ? Colors.red : AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cancelled
                        ? 'This appointment was cancelled.${s.cancelReason == null ? "" : " Reason: ${s.cancelReason}"}'
                        : 'You will get a reminder before this visit',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            cancelled ? Colors.red : const Color(0xFF5B21B6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
