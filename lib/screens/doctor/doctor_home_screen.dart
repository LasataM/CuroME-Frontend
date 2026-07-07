import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/doctor/doctor_tab.dart';
import 'package:curome/screens/doctor/doctor_home_tab.dart';
import 'package:curome/screens/doctor/doctor_appointments_tab.dart';
import 'package:curome/screens/doctor/doctor_mood_tab.dart';
import 'package:curome/screens/doctor/doctor_suggestions_tab.dart';
import 'package:curome/screens/doctor/doctor_visit_notes_tab.dart';
import 'package:curome/screens/doctor/doctor_messages_tab.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  DoctorTab _tab = DoctorTab.home;
  bool _showNotifications = false;

  void _goTo(DoctorTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      backgroundColor: AppColors.greyBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildTab(),
            if (_showNotifications) _notificationsOverlay(state),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case DoctorTab.home:
        return DoctorHomeTab(
          onNavigate: _goTo,
          onShowNotifications: () => setState(() => _showNotifications = true),
        );
      case DoctorTab.appointments:
        return DoctorAppointmentsTab(onBack: () => _goTo(DoctorTab.home));
      case DoctorTab.mood:
        return DoctorMoodTab(onBack: () => _goTo(DoctorTab.home));
      case DoctorTab.suggestions:
        return DoctorSuggestionsTab(onBack: () => _goTo(DoctorTab.home));
      case DoctorTab.visitNotes:
        return DoctorVisitNotesTab(onBack: () => _goTo(DoctorTab.home));
      case DoctorTab.messages:
        return DoctorMessagesTab(onBack: () => _goTo(DoctorTab.home));
    }
  }

  Widget _bottomNav() {
    final tabs = [
      (DoctorTab.home, 'Home', Icons.home),
      (DoctorTab.appointments, 'Slots', Icons.calendar_month),
      (DoctorTab.mood, 'Mood', Icons.trending_up),
      (DoctorTab.suggestions, 'Suggest', Icons.medication),
      (DoctorTab.visitNotes, 'Notes', Icons.description),
      (DoctorTab.messages, 'Messages', Icons.message),
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
              onTap: () => _goTo(t.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        size: 22,
                        color:
                            selected ? AppColors.indigo : Colors.grey.shade400),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? AppColors.indigo
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
