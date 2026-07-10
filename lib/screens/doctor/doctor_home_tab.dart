import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/doctor/doctor_tab.dart';

class DoctorHomeTab extends ConsumerWidget {
  final void Function(DoctorTab tab) onNavigate;
  final VoidCallback onShowNotifications;

  const DoctorHomeTab({
    super.key,
    required this.onNavigate,
    required this.onShowNotifications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final patients = state.doctorVisiblePatients;
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
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(state.doctorDisplayName,
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
                  unreadCount: state.unreadCountFor(Role.doctor),
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
          if (patients.isEmpty)
            const SizedBox(
              width: double.infinity,
              child: Center(
                child: EmptyState(
                  icon: Icons.person,
                  text: 'No patients assigned yet.',
                ),
              ),
            )
          else ...[
            PatientSelector(
              patients: patients,
              selectedId: state.selectedPatientId,
              onSelect: state.selectPatient,
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
                  _quickCard(
                      'Appointments',
                      Icons.calendar_month,
                      AppColors.indigo,
                      () => onNavigate(DoctorTab.appointments)),
                  _quickCard('Mood Trends', Icons.trending_up, AppColors.purple,
                      () => onNavigate(DoctorTab.mood)),
                  _quickCard(
                      'Suggestions',
                      Icons.medication,
                      Colors.green.shade700,
                      () => onNavigate(DoctorTab.suggestions)),
                  _quickCard(
                      'Visit Notes',
                      Icons.description,
                      Colors.amber.shade700,
                      () => onNavigate(DoctorTab.visitNotes)),
                  _quickCard('Messages', Icons.message, Colors.blue.shade700,
                      () => onNavigate(DoctorTab.messages)),
                ],
              ),
            ),
          ],
          if (state.alertTriggered && state.selectedPatient != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _alertBanner('Mood Alert — ${state.selectedPatient!.name}',
                  'Patient recorded 3+ consecutive sad check-ins.', Colors.red),
            ),
          if (state.awaitingApprovalSlots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  border: Border.all(
                      color: AppColors.indigo.withValues(alpha: 0.3)),
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
                            onTap: () => onNavigate(DoctorTab.appointments),
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
}
