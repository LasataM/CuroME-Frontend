import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';

class SignupSuccessScreen extends ConsumerWidget {
  const SignupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final patientId = state.generatedPatientId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Colors.white, Color(0xFFF5F3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 40, color: Color(0xFF059669)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Created!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to CuroME. Your unique Patient ID has been generated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Patient ID card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3), width: 2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR PATIENT ID',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        patientId,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3730A3),
                            letterSpacing: 3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save this ID — your caregiver will need it to link their account to yours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Warning banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please note down or screenshot your Patient ID. You cannot retrieve it later.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: AppSizes.minTouchTarget,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Go to My Dashboard',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}