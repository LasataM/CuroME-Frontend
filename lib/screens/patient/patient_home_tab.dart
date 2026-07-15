import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/screens/patient/patient_tab.dart';

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

class PatientHomeTab extends ConsumerWidget {
  final bool moodSubmitted;
  final int? selectedMood;
  final void Function(PatientTab tab) onNavigate;
  final Widget profileButton;

  const PatientHomeTab({
    super.key,
    required this.moodSubmitted,
    required this.selectedMood,
    required this.onNavigate,
    required this.profileButton,
  });

  void _confirmReminder(
      BuildContext context, String id, String label, AppState state) {
    state.takeMedicationReminder(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label marked as taken. Caregiver notified.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  profileButton,
                  const SizedBox(width: 8),
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
                  if (moodSubmitted && selectedMood != null)
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
                              Icon(moodIcon(selectedMood!),
                                  size: 34, color: moodColors[selectedMood!]),
                              const SizedBox(width: 10),
                              Text(moodLabels[selectedMood!] ?? '',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.patientText)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  _medicineCard(
                      context, state, nextReminder, reminders, allDone),
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
                    onTap: () => onNavigate(PatientTab.medicines),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.calendar_month,
                    iconColor: AppColors.purple,
                    title: 'My Appointments',
                    subtitle: state.confirmedSlots.isNotEmpty
                        ? 'Next: ${state.confirmedSlots.first.date}'
                        : 'No visits coming up',
                    onTap: () => onNavigate(PatientTab.appointments),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.chat_bubble_outline,
                    iconColor: AppColors.teal,
                    title: 'Get Help',
                    subtitle: 'Questions? Talk to your helper',
                    onTap: () => onNavigate(PatientTab.chatbot),
                  ),
                  const SizedBox(height: 12),
                  _navCard(
                    icon: Icons.message,
                    iconColor: AppColors.indigo,
                    title: 'Messages',
                    subtitle: 'Talk to your doctor or caregiver',
                    onTap: () => onNavigate(PatientTab.messages),
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

  Widget _medicineCard(BuildContext context, AppState state,
      Reminder? nextReminder, List<Reminder> reminders, bool allDone) {
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
                    context, nextReminder.id, nextReminder.label, state),
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
}
