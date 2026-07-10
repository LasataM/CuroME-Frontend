import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/services/api_service.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/widgets/common_widgets.dart';

class ClinicHomeScreen extends ConsumerStatefulWidget {
  const ClinicHomeScreen({super.key});

  @override
  ConsumerState<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends ConsumerState<ClinicHomeScreen> {
  int _tab = 0;

  static const _tabs = [
    ('Patients List', Icons.people_outline),
    ('Doctors List', Icons.medical_services_outlined),
    ('Assignments', Icons.assignment_ind_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      backgroundColor: AppColors.greyBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(state),
            _tabBar(),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _PatientsList(
                    onAssign: _showAssignDoctor,
                    onDetails: _showPatientDetails,
                  ),
                  const _DoctorsList(),
                  _AssignmentsList(onAssign: _showAssignDoctor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 24),
      color: AppColors.teal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CuroME Clinic Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatNow(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              state.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = _tab == index;
          final tab = _tabs[index];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                onTap: () => setState(() => _tab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: selected
                          ? AppColors.teal.withValues(alpha: 0.35)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.$2,
                          size: 18,
                          color: selected ? AppColors.teal : Colors.grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tab.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w600,
                            color: selected
                                ? AppColors.teal
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showPatientDetails(PatientProfile patient) {
    final state = ref.read(appStateProvider);
    final caregiver = state.caregiverNameForPatient(patient.id);
    final doctor = state.assignedDoctorNamesForPatient(patient.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(patient.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Patient ID', patient.id),
            _detailLine('Caregiver', caregiver),
            _detailLine(
              'Assigned Doctors',
              doctor.isEmpty ? 'Not assigned' : doctor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAssignDoctor(patient);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Assign Doctor',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showAssignDoctor(PatientProfile patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignDoctorSheet(patient: patient),
    );
  }
}

class _PatientsList extends ConsumerWidget {
  final ValueChanged<PatientProfile> onAssign;
  final ValueChanged<PatientProfile> onDetails;

  const _PatientsList({
    required this.onAssign,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    if (state.patients.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.person,
          text: 'No patients have signed up yet.',
        ),
      );
    }

    final orderedPatients = [
      ...state.patients
          .where((patient) => state.assignmentsForPatient(patient.id).isEmpty),
      ...state.patients.where(
          (patient) => state.assignmentsForPatient(patient.id).isNotEmpty),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orderedPatients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final patient = orderedPatients[index];
        final doctor = state.assignedDoctorNamesForPatient(patient.id);
        final pending = doctor.isEmpty;
        return _ClinicRow(
          leading: PatientAvatar(patient: patient, size: 42),
          title: patient.name,
          subtitle: 'Caregiver: ${state.caregiverNameForPatient(patient.id)}',
          meta: doctor.isEmpty
              ? 'Assigned Doctors: None'
              : 'Assigned Doctors: $doctor',
          badge: pending ? 'Pending Assignment' : 'Active',
          badgeColor: pending ? AppColors.warning : AppColors.success,
          actions: [
            TextButton(
              onPressed: () => onAssign(patient),
              child: const Text('Assign Doctor'),
            ),
            TextButton(
              onPressed: () => onDetails(patient),
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }
}

class _DoctorsList extends ConsumerWidget {
  const _DoctorsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final doctors = state.doctorAccounts;
    if (doctors.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.medical_services_outlined,
          text: 'No doctors have signed up yet.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final doctor = doctors[index];
        final available = state.isDoctorAvailable(doctor.email);
        final patients = state.assignedPatientsForDoctor(doctor.email);
        return _ClinicRow(
          leading: CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: AppColors.indigo),
          ),
          title: _doctorName(doctor.name),
          subtitle:
              'Specialization: ${doctor.specialization?.isNotEmpty == true ? doctor.specialization : 'General'}',
          meta:
              'Current Patient Load: ${state.patientLoadForDoctor(doctor.email)}',
          badge: available ? 'Available' : 'Unavailable',
          badgeColor: available ? AppColors.success : AppColors.danger,
          actions: [
            TextButton(
              onPressed: () => _showAssignedPatients(context, patients),
              child: const Text('View Assigned Patients'),
            ),
            TextButton(
              onPressed: () => state.toggleDoctorAvailability(doctor.email),
              child: Text(available ? 'Mark Unavailable' : 'Mark Availability'),
            ),
          ],
        );
      },
    );
  }

  static String _doctorName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final last = parts.length > 1 ? parts.last : name;
    return last.isEmpty
        ? 'Doctor'
        : 'Dr. ${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
  }

  void _showAssignedPatients(
      BuildContext context, List<PatientProfile> patients) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assigned Patients'),
        content: SizedBox(
          width: double.maxFinite,
          child: patients.isEmpty
              ? const Text('No patients assigned yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: PatientAvatar(patient: patients[index]),
                    title: Text(patients[index].name),
                    subtitle: Text(patients[index].id),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsList extends ConsumerWidget {
  final ValueChanged<PatientProfile> onAssign;

  const _AssignmentsList({required this.onAssign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    if (state.assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmptyState(
            icon: Icons.assignment_ind_outlined,
            text: 'No doctor assignments have been created yet.',
          ),
          for (final patient in state.patients)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton.icon(
                onPressed: () => onAssign(patient),
                icon: const Icon(Icons.add),
                label: Text('Assign doctor to ${patient.shortName}'),
              ),
            ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final assignment =
            state.assignments[state.assignments.length - 1 - index];
        final patient =
            state.patients.where((p) => p.id == assignment.patientId);
        final patientProfile = patient.isEmpty ? null : patient.first;
        final doctorName =
            state.doctorDisplayNameForEmail(assignment.doctorEmail);
        return _ClinicRow(
          leading: patientProfile == null
              ? CircleAvatar(
                  backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                  child:
                      const Icon(Icons.person_outline, color: AppColors.teal),
                )
              : PatientAvatar(patient: patientProfile, size: 42),
          title: patientProfile?.name ?? assignment.patientId,
          subtitle: 'Doctor: $doctorName',
          meta: 'Assigned: ${assignment.assignedAt}',
          badge: 'Active',
          badgeColor: AppColors.success,
          actions: [
            if (patientProfile != null)
              TextButton(
                onPressed: () => onAssign(patientProfile),
                child: const Text('Assign Doctor'),
              ),
            TextButton(
              onPressed: () => state.removeDoctorFromPatient(
                assignment.patientId,
                assignment.doctorEmail,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

class _AssignDoctorSheet extends ConsumerStatefulWidget {
  final PatientProfile patient;

  const _AssignDoctorSheet({required this.patient});

  @override
  ConsumerState<_AssignDoctorSheet> createState() => _AssignDoctorSheetState();
}

class _AssignDoctorSheetState extends ConsumerState<_AssignDoctorSheet> {
  String? _doctorEmail;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final assignedDoctors = state.doctorsForPatient(widget.patient.id);
    final assignedDoctorEmails =
        assignedDoctors.map((doctor) => doctor.email).toSet();
    final availableDoctors = state.doctorAccounts
        .where((doctor) => !assignedDoctorEmails.contains(doctor.email))
        .toList();

    final validSelectedEmail = availableDoctors.any((d) => d.email == _doctorEmail)
    ? _doctorEmail
    : null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Assign Doctor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PatientSummary(patient: widget.patient),
            if (assignedDoctors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Assigned Doctors',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignedDoctors
                    .map((doctor) => InputChip(
                          label:
                              Text(state.doctorDisplayNameForAccount(doctor)),
                          onDeleted: _saving
                              ? null
                              : () => state.removeDoctorFromPatient(
                                    widget.patient.id,
                                    doctor.email,
                                  ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: validSelectedEmail,   // was: _doctorEmail
              decoration: const InputDecoration(labelText: 'Select Doctor'),
              items: availableDoctors
                .map((doctor) => DropdownMenuItem(
                      value: doctor.email,
                      child: Text(
                        '${_DoctorsList._doctorName(doctor.name)}'
                        ' (${doctor.specialization?.isNotEmpty == true ? doctor.specialization : 'General'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
              onChanged: _saving
                ? null
                : (value) => setState(() => _doctorEmail = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppSizes.minTouchTarget,
              child: ElevatedButton(
                onPressed:
                    availableDoctors.isEmpty || _doctorEmail == null || _saving
                        ? null
                        : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Text(
                  _saving ? 'Assigning...' : 'Confirm Assignment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final doctorEmail = _doctorEmail;
    if (doctorEmail == null) return;

    setState(() => _saving = true);
    final state = ref.read(appStateProvider);
    state.assignDoctorToPatient(widget.patient.id, doctorEmail);

    try {
      await ApiService.instance.assignDoctor(widget.patient.id, doctorEmail);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assignment saved locally. Backend sync is unavailable right now.',
            ),
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }
}

class _PatientSummary extends ConsumerWidget {
  final PatientProfile patient;

  const _PatientSummary({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PatientAvatar(patient: patient, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        'Caregiver: ${state.caregiverNameForPatient(patient.id)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClinicRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String meta;
  final String badge;
  final Color badgeColor;
  final List<Widget> actions;

  const _ClinicRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.badgeColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      Text(meta,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
