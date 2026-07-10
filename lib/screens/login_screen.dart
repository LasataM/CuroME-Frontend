import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.indigo,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.indigo.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('CuroME',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3730A3))),
                const SizedBox(height: 6),
                Text(
                  'Choose your role to continue',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 48),
                RoleCard(
                  role: Role.doctor,
                  label: 'Doctor',
                  icon: Icons.person,
                  color: AppColors.indigo,
                  onSelect: (r) => Navigator.pushNamed(
                      context, '/signin',
                      arguments: r),
                ),
                const SizedBox(height: 14),
                RoleCard(
                  role: Role.caregiver,
                  label: 'Caregiver',
                  icon: Icons.favorite_border,
                  color: AppColors.emerald,
                  onSelect: (r) => Navigator.pushNamed(
                      context, '/signin',
                      arguments: r),
                ),
                const SizedBox(height: 14),
                RoleCard(
                  role: Role.patient,
                  label: 'Patient',
                  icon: Icons.monitor_heart_outlined,
                  color: AppColors.purple,
                  onSelect: (r) => Navigator.pushNamed(
                      context, '/signin',
                      arguments: r),
                ),
                const SizedBox(height: 14),
                RoleCard(
                  role: Role.clinicAdmin,
                  label: 'Clinic Admin',
                  icon: Icons.local_hospital_outlined,
                  color: AppColors.teal,
                  onSelect: (r) => Navigator.pushNamed(
                      context, '/signin',
                      arguments: r),
                ),
                const SizedBox(height: 24),
                Text(
                  'Role is assigned at account creation',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
