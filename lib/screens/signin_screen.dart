import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  Role _role = Role.patient;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  String? _authError;
  Map<String, String> _errors = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Role) _role = arg;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email.';
    }
    if (password.isEmpty) errors['password'] = 'Password is required.';

    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _authError = null;
      });
      return;
    }

    final state = ref.read(appStateProvider);
    await state.ensureAuthLoaded();
    if (!mounted) return;
    final match = state.signIn(email, password);
    if (match == null) {
      setState(() {
        _errors = {};
        _authError = 'Incorrect email or password. Please try again.';
      });
      return;
    }

    Navigator.pushReplacementNamed(context, _dashboardRoute(match.role));
  }

  String _dashboardRoute(Role r) {
    switch (r) {
      case Role.doctor:
        return '/doctor';
      case Role.caregiver:
        return '/caregiver';
      case Role.patient:
        return '/patient';
      case Role.clinicAdmin:
        return '/clinic';
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
              // Back button
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: _accent),
              ),
              const SizedBox(height: 8),
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 12),
                    const Text('CuroME',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3730A3))),
                    const SizedBox(height: 4),
                    const Text('Welcome back',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Card
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
                      const Text('Signing in as',
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
                      const SizedBox(height: 20),

                      // Email
                      _label('Email Address'),
                      _field(
                        controller: _emailCtrl,
                        hint: 'name@email.com',
                        keyboardType: TextInputType.emailAddress,
                        error: _errors['email'],
                        onChanged: (_) => setState(() => _authError = null),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _label('Password'),
                      _passwordField(),
                      const SizedBox(height: 6),
                      if (_errors['password'] != null)
                        _errorText(_errors['password']!),
                      const SizedBox(height: 20),

                      // Auth error
                      if (_authError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_authError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),

                      // Submit
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
                          child: const Text('Sign In',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signup',
                                arguments: _role),
                            child: Text('Sign Up',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child:
            Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? error,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: _accent, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (error != null) _errorText(error),
      ],
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: !_showPassword,
      onChanged: (_) => setState(() => _authError = null),
      decoration: InputDecoration(
        hintText: '••••••••',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: _accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }
}
