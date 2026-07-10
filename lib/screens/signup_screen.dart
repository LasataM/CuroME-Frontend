import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  Role _role = Role.patient;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _linkedPatientCtrl = TextEditingController();

  String? _gender;
  bool _showPass = false;
  bool _showConfirm = false;
  Map<String, String> _errors = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Role) setState(() => _role = arg);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _ageCtrl,
      _phoneCtrl,
      _emailCtrl,
      _passwordCtrl,
      _confirmCtrl,
      _specializationCtrl,
      _licenseCtrl,
      _linkedPatientCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Color get _accent => _role == Role.doctor
      ? AppColors.indigo
      : _role == Role.caregiver
          ? AppColors.emerald
          : _role == Role.clinicAdmin
              ? AppColors.teal
              : AppColors.purple;

  Future<void> _submit() async {
    final errors = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) {
      errors['name'] = 'Full name is required.';
    }
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 1 || age > 120) {
      errors['age'] = 'Please enter a valid age (1–120).';
    }
    if (_gender == null) errors['gender'] = 'Please select a gender.';
    if (_phoneCtrl.text.trim().isEmpty) errors['phone'] = 'Phone is required.';
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email.';
    }
    if (_role == Role.doctor) {
      if (_specializationCtrl.text.trim().isEmpty) {
        errors['specialization'] = 'Specialization is required.';
      }
      if (_licenseCtrl.text.trim().isEmpty) {
        errors['license'] = 'License number is required.';
      }
    }
    if (_role == Role.caregiver) {
      if (_linkedPatientCtrl.text.trim().isEmpty) {
        errors['linkedPatient'] = 'Patient ID is required.';
      }
    }
    final state = ref.read(appStateProvider);
    await state.ensureAuthLoaded();
    if (!mounted) return;
    if (state.accountExists(email)) {
      errors['email'] = 'An account with this email already exists.';
    }
    if (_passwordCtrl.text.isEmpty) {
      errors['password'] = 'Password is required.';
    } else if (_passwordCtrl.text.length < 6) {
      errors['password'] = 'Password must be at least 6 characters.';
    }
    if (_confirmCtrl.text.isEmpty) {
      errors['confirm'] = 'Please confirm your password.';
    } else if (_passwordCtrl.text != _confirmCtrl.text) {
      errors['confirm'] = 'Passwords do not match.';
    }

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    final patientId = _role == Role.patient
        ? 'PAT-${(100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString()}'
        : null;

    final account = StoredAccount(
      email: email.toLowerCase(),
      password: _passwordCtrl.text,
      role: _role,
      name: _nameCtrl.text.trim(),
      age: age,
      gender: _gender,
      phone: _phoneCtrl.text.trim(),
      specialization: _specializationCtrl.text.trim().isEmpty
          ? null
          : _specializationCtrl.text.trim(),
      licenseNumber:
          _licenseCtrl.text.trim().isEmpty ? null : _licenseCtrl.text.trim(),
      linkedPatientId: _linkedPatientCtrl.text.trim().isEmpty
          ? null
          : _linkedPatientCtrl.text.trim(),
      patientId: patientId,
    );

    state.signUp(account);

    if (_role == Role.patient) {
      Navigator.pushReplacementNamed(context, '/signup_success');
    } else if (_role == Role.doctor) {
      Navigator.pushReplacementNamed(context, '/doctor');
    } else if (_role == Role.clinicAdmin) {
      Navigator.pushReplacementNamed(context, '/clinic');
    } else {
      Navigator.pushReplacementNamed(context, '/caregiver');
    }
  }

  String _roleLabel(Role role) {
    switch (role) {
      case Role.doctor:
        return 'Doctor';
      case Role.caregiver:
        return 'Caregiver';
      case Role.patient:
        return 'Patient';
      case Role.clinicAdmin:
        return 'Clinic Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabel(_role);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: _accent),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration:
                          BoxDecoration(color: _accent, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 10),
                    const Text('CuroME',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3730A3))),
                    const Text('Create your account',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                color: Colors.white.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role badge
                      const Text('Your role',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(roleLabel,
                            style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      const SizedBox(height: 18),
                      _field('Full Name', _nameCtrl, 'Henry Winter',
                          error: _errors['name']),
                      _field('Age', _ageCtrl, '25',
                          type: TextInputType.number, error: _errors['age']),
                      _genderPicker(),
                      if (_errors['gender'] != null) _err(_errors['gender']!),
                      _field('Phone Number', _phoneCtrl, '+977 9841234567',
                          type: TextInputType.phone, error: _errors['phone']),
                      _field('Email Address', _emailCtrl, 'henry@email.com',
                          type: TextInputType.emailAddress,
                          error: _errors['email']),

                      // Doctor-specific
                      if (_role == Role.doctor) ...[
                        _field('Specialization', _specializationCtrl,
                            'e.g. Neurology, Geriatrics',
                            error: _errors['specialization']),
                        _field(
                            'License Number', _licenseCtrl, 'e.g. NMC-123456',
                            error: _errors['license']),
                      ],

                      // Caregiver-specific
                      if (_role == Role.caregiver) ...[
                        const SizedBox(height: 4),
                        const Text('Patient ID',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Enter your patient\'s ID to link accounts',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        _field('', _linkedPatientCtrl, 'PAT-123456',
                            error: _errors['linkedPatient']),
                      ],

                      _passwordField('Password', _passwordCtrl, _showPass,
                          () => setState(() => _showPass = !_showPass),
                          error: _errors['password']),
                      _passwordField(
                          'Confirm Password',
                          _confirmCtrl,
                          _showConfirm,
                          () => setState(() => _showConfirm = !_showConfirm),
                          error: _errors['confirm']),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.minTouchTarget,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                            ),
                          ),
                          child: const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/signin',
                                arguments: _role),
                            child: Text('Sign In',
                                style: TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? type,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: _inputDec(hint),
          ),
          if (error != null) _err(error),
        ],
      ),
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController ctrl,
    bool visible,
    VoidCallback toggle, {
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: !visible,
            decoration: _inputDec('••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: toggle,
              ),
            ),
          ),
          if (error != null) _err(error),
        ],
      ),
    );
  }

  Widget _genderPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Male', 'Female', 'Prefer not to say'].map((g) {
              final sel = _gender == g;
              return GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _accent : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(g,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey.shade700)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _err(String msg) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child:
            Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12)),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide(color: _accent, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
