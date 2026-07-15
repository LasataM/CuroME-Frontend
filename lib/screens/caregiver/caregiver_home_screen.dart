import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';
import 'package:curome/screens/caregiver/caregiver_tab.dart';
import 'package:curome/screens/caregiver/caregiver_home_tab.dart';
import 'package:curome/screens/caregiver/caregiver_appointments_tab.dart';
import 'package:curome/screens/caregiver/caregiver_suggestions_tab.dart';
import 'package:curome/screens/caregiver/caregiver_mood_tab.dart';
import 'package:curome/screens/caregiver/caregiver_visit_notes_tab.dart';
import 'package:curome/screens/caregiver/caregiver_reminders_tab.dart';
import 'package:curome/screens/caregiver/caregiver_messages_tab.dart';
import 'package:curome/screens/profile_screen.dart';

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen> {
  CaregiverTab _tab = CaregiverTab.home;
  bool _showNotifications = false;

  void _goTo(CaregiverTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      backgroundColor: AppColors.greyBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildTab(),
            Positioned(
              top: 8,
              right: 10,
              child: _profileButton(context),
            ),
            if (_showNotifications) _notificationsOverlay(state),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _profileButton(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.account_circle, color: AppColors.emerald),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      );

  Widget _buildTab() {
    switch (_tab) {
      case CaregiverTab.home:
        return CaregiverHomeTab(
          onNavigate: _goTo,
          onShowNotifications: () => setState(() => _showNotifications = true),
        );
      case CaregiverTab.appointments:
        return CaregiverAppointmentsTab(
            onBack: () => _goTo(CaregiverTab.home));
      case CaregiverTab.suggestions:
        return CaregiverSuggestionsTab(
            onBack: () => _goTo(CaregiverTab.home));
      case CaregiverTab.mood:
        return CaregiverMoodTab(onBack: () => _goTo(CaregiverTab.home));
      case CaregiverTab.visit:
        return CaregiverVisitNotesTab(
            onBack: () => _goTo(CaregiverTab.home));
      case CaregiverTab.reminders:
        return CaregiverRemindersTab(
            onBack: () => _goTo(CaregiverTab.home));
      case CaregiverTab.messages:
        return CaregiverMessagesTab(onBack: () => _goTo(CaregiverTab.home));
    }
  }

  Widget _bottomNav() {
    final tabs = [
      (CaregiverTab.home, 'Home', Icons.home),
      (CaregiverTab.appointments, 'Appts', Icons.calendar_month),
      (CaregiverTab.suggestions, 'Suggest', Icons.assignment),
      (CaregiverTab.mood, 'Mood', Icons.trending_up),
      (CaregiverTab.reminders, 'Meds', Icons.medication),
      (CaregiverTab.visit, 'Visit', Icons.description),
      (CaregiverTab.messages, 'Messages', Icons.message),
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
