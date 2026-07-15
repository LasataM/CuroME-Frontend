import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/state/app_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Color _accent(Role role) => switch (role) {
        Role.doctor => AppColors.indigo,
        Role.caregiver => AppColors.emerald,
        Role.patient => AppColors.purple,
        Role.clinicAdmin => AppColors.teal,
      };

  String _roleLabel(Role role) => switch (role) {
        Role.doctor => 'Doctor',
        Role.caregiver => 'Caregiver',
        Role.patient => 'Patient',
        Role.clinicAdmin => 'Clinic Admin',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final account = state.currentAccount;
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Account unavailable.')));
    }
    final accent = _accent(account.role);
    return Scaffold(
      backgroundColor: AppColors.greyBg,
      appBar: AppBar(
        title: const Text('Personal Information'),
        foregroundColor: Colors.white,
        backgroundColor: accent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(_roleLabel(account.role),
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detail('Name', account.name),
                  _detail('Age', account.age?.toString() ?? 'Not provided'),
                  _detail('Gender', account.gender ?? 'Not provided'),
                  _detail('Phone number', account.phone ?? 'Not provided'),
                  _detail('Email address', account.email),
                  if (account.role == Role.doctor) ...[
                    _detail('Specialization', account.specialization ?? 'Not provided'),
                    _detail('License number', account.licenseNumber ?? 'Not provided'),
                  ],
                  if (account.role == Role.patient)
                    _detail('Patient ID', account.patientId ?? 'Not provided'),
                  if (account.role == Role.caregiver)
                    _detail('Linked patient ID', account.linkedPatientId ?? 'Not provided'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              state.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
                foregroundColor: accent, minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, state),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete account'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(50)),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 118,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete permanently')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await state.deleteCurrentAccount();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}
