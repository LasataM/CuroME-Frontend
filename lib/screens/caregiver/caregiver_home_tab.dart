import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/caregiver/caregiver_tab.dart';

class CaregiverHomeTab extends ConsumerWidget {
  final void Function(CaregiverTab tab) onNavigate;
  final VoidCallback onShowNotifications;

  const CaregiverHomeTab({
    super.key,
    required this.onNavigate,
    required this.onShowNotifications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
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
                  onTap: onShowNotifications,
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
                                    onNavigate(CaregiverTab.appointments),
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
                        () => onNavigate(CaregiverTab.appointments)),
                    _quickCard(
                        'Suggestions',
                        Icons.assignment,
                        Colors.green.shade700,
                        () => onNavigate(CaregiverTab.suggestions)),
                    _quickCard('Mood Check-ins', Icons.trending_up,
                        AppColors.purple, () => onNavigate(CaregiverTab.mood)),
                    _quickCard(
                        'Medicine',
                        Icons.medication,
                        Colors.blue.shade700,
                        () => onNavigate(CaregiverTab.reminders)),
                    _quickCard(
                        'Visit Notes',
                        Icons.description,
                        Colors.amber.shade800,
                        () => onNavigate(CaregiverTab.visit)),
                    _quickCard('Messages', Icons.message, AppColors.emerald,
                        () => onNavigate(CaregiverTab.messages)),
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
}
