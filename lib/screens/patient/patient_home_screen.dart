import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/notifications/notification_service.dart';
import 'package:curome/models/models.dart';
import 'package:curome/screens/patient/patient_tab.dart';
import 'package:curome/screens/patient/patient_widgets.dart';
import 'package:curome/screens/patient/patient_home_tab.dart';
import 'package:curome/screens/patient/patient_medicines_tab.dart';
import 'package:curome/screens/patient/patient_appointments_tab.dart';
import 'package:curome/screens/patient/patient_chatbot_tab.dart';
import 'package:curome/screens/patient/patient_messages_tab.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  PatientTab _tab = PatientTab.home;

  bool _moodSubmitted = false;
  int? _selectedMood;
  bool _moodToastVisible = false;
  Timer? _moodToastTimer;

  int? _sosCountdown;
  Timer? _sosTimer;
  bool _sosFired = false;

  String? _undoReminderId;
  final String _undoLabel = '';
  Timer? _undoTimer;

  @override
  void dispose() {
    _moodToastTimer?.cancel();
    _sosTimer?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _submitMood(int mood, AppState state) {
    state.submitMood(mood);
    setState(() {
      _selectedMood = mood;
      _moodSubmitted = true;
      _moodToastVisible = true;
    });
    _moodToastTimer?.cancel();
    _moodToastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _moodToastVisible = false);
    });
  }

  void _undo(AppState state) {
    if (_undoReminderId == null) return;
    state.undoReminder(_undoReminderId!);
    setState(() => _undoReminderId = null);
  }

  void _startSos(AppState state) {
    setState(() {
      _sosCountdown = 5;
      _sosFired = false;
    });
    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final current = _sosCountdown ?? 0;
      if (current <= 1) {
        t.cancel();
        setState(() {
          _sosCountdown = null;
          _sosFired = true;
        });
        NotificationService.instance
            .sendSosAlert(state.session?.name ?? 'Patient');
        final caregivers =
            state.caregiverEmailsForPatient(state.generatedPatientId);
        for (final caregiverEmail in caregivers) {
          state.pushNotification(
              '${state.patientFirstName} has triggered an SOS request.',
              Role.caregiver,
              targetAccountEmail: caregiverEmail);
        }
      } else {
        setState(() => _sosCountdown = current - 1);
      }
    });
  }

  void _cancelSos() {
    _sosTimer?.cancel();
    setState(() => _sosCountdown = null);
  }

  void _goTo(PatientTab tab) => setState(() => _tab = tab);

  void _goHome() => setState(() => _tab = PatientTab.home);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        children: [
          _buildTab(),
          if (!_moodSubmitted && state.shouldShowMoodCheck)
            _buildMoodModal(state),
          if (_moodToastVisible) _buildMoodToast(),
          if (_undoReminderId != null) _buildUndoToast(state),
          if (_sosCountdown != null) _buildSosCountdown(),
          if (_sosFired) _buildSosFired(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PatientBottomNav(
            active: _tab,
            onSelect: _goTo,
          ),
          SOSButton(onTrigger: () => _startSos(state)),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case PatientTab.home:
        return PatientHomeTab(
          moodSubmitted: _moodSubmitted,
          selectedMood: _selectedMood,
          onNavigate: _goTo,
        );
      case PatientTab.medicines:
        return PatientMedicinesTab(onBack: _goHome, onHome: _goHome);
      case PatientTab.appointments:
        return PatientAppointmentsTab(onBack: _goHome, onHome: _goHome);
      case PatientTab.chatbot:
        return PatientChatbotTab(onHome: _goHome);
      case PatientTab.messages:
        return PatientMessagesTab(onBack: _goHome, onHome: _goHome);
    }
  }

  // ── Overlays ──
  Widget _buildMoodModal(AppState state) {
    return Container(
      color: Colors.purple.shade900.withValues(alpha: 0.88),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.patientBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Good morning, ${state.patientFirstName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patientText)),
            const SizedBox(height: 6),
            const Text('How do you feel today?',
                style: TextStyle(fontSize: 17, color: Color(0xFF555555))),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in [
                  (
                    1,
                    'Very Sad',
                    Icons.sentiment_very_dissatisfied,
                    const Color(0xFF6B7280)
                  ),
                  (
                    2,
                    'Sad',
                    Icons.sentiment_dissatisfied,
                    const Color(0xFFD97706)
                  ),
                  (3, 'Okay', Icons.sentiment_neutral, const Color(0xFFCA8A04)),
                  (
                    4,
                    'Good',
                    Icons.sentiment_satisfied,
                    const Color(0xFF0D9488)
                  ),
                  (
                    5,
                    'Happy',
                    Icons.sentiment_very_satisfied,
                    const Color(0xFF16A34A)
                  ),
                ])
                  GestureDetector(
                    onTap: () => _submitMood(opt.$1, state),
                    child: Container(
                      width: 62,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.patientBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt.$3, color: opt.$4, size: 26),
                          const SizedBox(height: 4),
                          Text(opt.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Tap one to check in',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodToast() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  'Done! Well done, ${ref.read(appStateProvider).patientFirstName}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Colors.yellowAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUndoToast(AppState state) {
    return Positioned(
      bottom: 180,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$_undoLabel marked as taken',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
            TextButton(
              onPressed: () => _undo(state),
              child: const Text('Undo',
                  style: TextStyle(
                      color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosCountdown() {
    return Container(
      color: Colors.red.shade700,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 80),
          const SizedBox(height: 16),
          Text('SOS in ${_sosCountdown}s',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Calling emergency contact…',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _cancelSos,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSosFired() {
    return Container(
      color: Colors.red.shade800,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 80),
          const SizedBox(height: 16),
          const Text('Alert Sent',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text('Call and SMS dispatched to your emergency contact.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _sosFired = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            child: const Text('OK',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
