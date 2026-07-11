import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curome/models/models.dart';
import 'package:curome/database/database_helper.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/notifications/notification_service.dart';

String nowTime() => DateFormat('h:mm a').format(DateTime.now());
String formatNow() => DateFormat('EEEE, d MMMM y').format(DateTime.now());

class AppState extends ChangeNotifier {
  static const _accountsPrefsKey = 'curome_accounts_v1';
  static const _moodCheckPrefsKey = 'curome_mood_checks_v1';
  static const _assignmentsPrefsKey = 'curome_assignments_v1';
  static const _doctorAvailabilityPrefsKey = 'curome_doctor_availability_v1';

  final DatabaseHelper db = DatabaseHelper();

  bool _accountsLoaded = false;
  final Map<String, Timer> _reminderTimers = {};

  AppState() {
    ensureAuthLoaded();
  }

  @override
  void dispose() {
    for (final timer in _reminderTimers.values) {
      timer.cancel();
    }
    _reminderTimers.clear();
    super.dispose();
  }

  Session? session;
  Role? role;

  final List<StoredAccount> storedAccounts = [];
  final List<PatientProfile> patients = [];
  final List<CaregiverContact> caregiverContacts = [];
  final List<MoodEntry> moodHistory = [];
  final Map<String, List<MoodEntry>> patientMoodData = {};
  final List<AppAppointment> appointments = [];
  final Map<String, List<ChatMessage>> patientMessages = {};
  final Map<String, List<ChatMessage>> docCgThreads = {};
  final List<ChatMessage> cgDoctorThread = [];
  final Map<String, List<ChatMessage>> caregiverPatientThreads = {};
  final List<Reminder> reminders = [];
  final List<PatientSuggestion> suggestions = [];
  final List<VisitNote> visitNotes = [];
  final List<AppointmentSlot> slots = [];
  final List<AppNotification> notifications = [];
  final List<PatientDoctorAssignment> assignments = [];
  final Set<String> unavailableDoctorEmails = {};

  String selectedPatientId = '';
  String linkedDoctorName = '';
  String linkedPatientName = '';
  String generatedPatientId = '';
  String currentAccountEmail = '';
  final Map<String, String> _lastMoodCheckByPatient = {};

  Future<void> ensureAuthLoaded() async {
    if (_accountsLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final rawAccounts = prefs.getString(_accountsPrefsKey);
    if (rawAccounts != null && rawAccounts.isNotEmpty) {
      final decoded = jsonDecode(rawAccounts);
      if (decoded is List) {
        storedAccounts
          ..clear()
          ..addAll(decoded
              .whereType<Map>()
              .map((row) => _accountFromJson(Map<String, dynamic>.from(row))));
        _rebuildDirectoryFromAccounts();
      }
    }

    final rawMoodChecks = prefs.getString(_moodCheckPrefsKey);
    if (rawMoodChecks != null && rawMoodChecks.isNotEmpty) {
      final decoded = jsonDecode(rawMoodChecks);
      if (decoded is Map) {
        _lastMoodCheckByPatient
          ..clear()
          ..addAll(decoded.map((key, value) =>
              MapEntry(key.toString(), value?.toString() ?? '')));
      }
    }

    final rawAssignments = prefs.getString(_assignmentsPrefsKey);
    if (rawAssignments != null && rawAssignments.isNotEmpty) {
      final decoded = jsonDecode(rawAssignments);
      if (decoded is List) {
        assignments
          ..clear()
          ..addAll(decoded.whereType<Map>().map(
              (row) => _assignmentFromJson(Map<String, dynamic>.from(row))));
      }
    }

    final rawAvailability = prefs.getString(_doctorAvailabilityPrefsKey);
    if (rawAvailability != null && rawAvailability.isNotEmpty) {
      final decoded = jsonDecode(rawAvailability);
      if (decoded is List) {
        unavailableDoctorEmails
          ..clear()
          ..addAll(decoded.map((value) => value.toString()));
      }
    }

    _accountsLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsPrefsKey,
      jsonEncode(storedAccounts.map(_accountToJson).toList()),
    );
  }

  Future<void> _saveMoodCheckDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _moodCheckPrefsKey, jsonEncode(_lastMoodCheckByPatient));
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _assignmentsPrefsKey,
      jsonEncode(assignments.map(_assignmentToJson).toList()),
    );
  }

  Future<void> _saveDoctorAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _doctorAvailabilityPrefsKey,
      jsonEncode(unavailableDoctorEmails.toList()),
    );
  }

  bool accountExists(String email) {
    final normalized = email.trim().toLowerCase();
    return storedAccounts.any((account) => account.email == normalized);
  }

  Map<String, dynamic> _accountToJson(StoredAccount account) => {
        'email': account.email,
        'password': account.password,
        'role': account.role.name,
        'name': account.name,
        'age': account.age,
        'gender': account.gender,
        'phone': account.phone,
        'specialization': account.specialization,
        'licenseNumber': account.licenseNumber,
        'linkedPatientId': account.linkedPatientId,
        'patientId': account.patientId,
      };

  StoredAccount _accountFromJson(Map<String, dynamic> json) => StoredAccount(
        email: (json['email'] ?? '').toString(),
        password: (json['password'] ?? '').toString(),
        role: roleFromString((json['role'] ?? '').toString()),
        name: (json['name'] ?? '').toString(),
        age: json['age'] is int
            ? json['age'] as int
            : int.tryParse('${json['age']}'),
        gender: json['gender']?.toString(),
        phone: json['phone']?.toString(),
        specialization: json['specialization']?.toString(),
        licenseNumber: json['licenseNumber']?.toString(),
        linkedPatientId: json['linkedPatientId']?.toString(),
        patientId: json['patientId']?.toString(),
      );

  Map<String, dynamic> _assignmentToJson(PatientDoctorAssignment assignment) =>
      {
        'id': assignment.id,
        'patientId': assignment.patientId,
        'doctorEmail': assignment.doctorEmail,
        'assignedAt': assignment.assignedAt,
      };

  PatientDoctorAssignment _assignmentFromJson(Map<String, dynamic> json) =>
      PatientDoctorAssignment(
        id: (json['id'] ?? newId()).toString(),
        patientId: (json['patientId'] ?? '').toString(),
        doctorEmail: (json['doctorEmail'] ?? '').toString(),
        assignedAt: (json['assignedAt'] ?? '').toString(),
      );

  void _applyAccountSession(StoredAccount account) {
    session = Session(loggedIn: true, role: account.role, name: account.name);
    role = account.role;
    currentAccountEmail = account.email;

    if (account.role == Role.patient) {
      generatedPatientId = account.patientId ?? '';
      _ensurePatientProfile(account);
      selectedPatientId = account.patientId ?? selectedPatientId;
      _syncPatientLinks();
    }

    if (account.role == Role.caregiver) {
      _syncCaregiverLinks(account);
    }

    if (account.role == Role.clinicAdmin) {
      _syncPatientLinks();
    }
  }

  void _rebuildDirectoryFromAccounts() {
    patients.clear();
    caregiverContacts.clear();

    for (final account in storedAccounts.where((a) => a.role == Role.patient)) {
      _ensurePatientProfile(account);
    }

    for (final account
        in storedAccounts.where((a) => a.role == Role.caregiver)) {
      final initials = _initialsFor(account.name, fallback: 'C');
      caregiverContacts.add(CaregiverContact(
        id: account.email,
        name: account.name,
        shortName: _firstName(account.name),
        initials: initials,
        avatarColor: 0xFF059669,
        patientName:
            _patientNameForId(account.linkedPatientId) ?? 'Linked patient',
      ));
    }

    if (selectedPatientId.isEmpty && patients.isNotEmpty) {
      selectedPatientId = patients.first.id;
    }
  }

  void _ensurePatientProfile(StoredAccount account) {
    final patientId = account.patientId ?? account.email;
    if (patients.any((patient) => patient.id == patientId)) return;

    patients.add(PatientProfile(
      id: patientId,
      name: account.name,
      shortName: _firstName(account.name),
      initials: _initialsFor(account.name, fallback: 'P'),
      avatarColor: 0xFF7C3AED,
    ));
  }

  void _syncCaregiverLinks(StoredAccount account) {
    linkedPatientName = _patientNameForId(account.linkedPatientId) ?? '';

    _syncPatientLinks();
  }

  void _syncPatientLinks() {
    final patientId = generatedPatientId.isNotEmpty
        ? generatedPatientId
        : selectedPatientId.isNotEmpty
            ? selectedPatientId
            : linkedCaregiverPatientId;
    final assignedName = assignedDoctorNamesForPatient(patientId);
    if (assignedName.isNotEmpty) {
      linkedDoctorName = assignedName;
      return;
    }

    linkedDoctorName = '';
  }

  String? _patientNameForId(String? patientId) {
    if (patientId == null || patientId.isEmpty) return null;
    try {
      return storedAccounts
          .firstWhere((a) => a.role == Role.patient && a.patientId == patientId)
          .name;
    } catch (_) {
      return null;
    }
  }

  String _firstName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? name : parts.first;
  }

  String _lastName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? name : parts.last;
  }

  String _initialsFor(String name, {required String fallback}) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? fallback : initials;
  }

  PatientProfile? get selectedPatient {
    final visiblePatients =
        role == Role.doctor ? doctorVisiblePatients : patients;
    try {
      return visiblePatients.firstWhere((p) => p.id == selectedPatientId);
    } catch (_) {
      return visiblePatients.isNotEmpty ? visiblePatients.first : null;
    }
  }

  String get doctorDisplayName {
    final parts = (session?.name ?? '').trim().split(RegExp(r'\s+'));
    final last = parts.length > 1 ? parts.last : (session?.name ?? '');
    if (last.isEmpty) return 'Dr.';
    return 'Dr. ${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
  }

  String get caregiverFirstName {
    final parts = (session?.name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final f = parts.first;
    return '${f[0].toUpperCase()}${f.substring(1).toLowerCase()}';
  }

  String get patientFirstName => caregiverFirstName;

  String get linkedCaregiverPatientId {
    if (role != Role.caregiver || currentAccountEmail.isEmpty) return '';
    try {
      return storedAccounts
              .firstWhere((account) => account.email == currentAccountEmail)
              .linkedPatientId ??
          '';
    } catch (_) {
      return '';
    }
  }

  List<AppointmentSlot> get publishedAvailableSlots => slots
      .where((s) => s.status == SlotStatus.available && s.published)
      .toList();
  List<AppointmentSlot> get awaitingApprovalSlots => doctorScopedSlots
      .where((s) => s.status == SlotStatus.pendingDoctor && !s.escalated)
      .toList();
  List<AppointmentSlot> get cancellationApprovalSlots => doctorScopedSlots
      .where((s) => s.status == SlotStatus.pendingCancellation)
      .toList();
  List<AppointmentSlot> get confirmedSlots => _visiblePatientSlots
      .where((s) => s.status == SlotStatus.confirmed)
      .toList();
  List<AppointmentSlot> get cancelledSlots => _visiblePatientSlots
      .where((s) => s.status == SlotStatus.cancelled)
      .toList();
  List<AppointmentSlot> get slotsPendingCaregiver => _visiblePatientSlots
      .where((s) => s.status == SlotStatus.pendingCaregiver)
      .toList();
  List<Reminder> get medicationReminders {
    final list = reminders.where((r) => r.type == 'medication').toList();
    list.sort((a, b) => _reminderSortValue(a).compareTo(_reminderSortValue(b)));
    return list;
  }

  List<AppNotification> notificationsFor(Role r) => notifications.where((n) {
        if (n.role != r) return false;
        return n.targetAccountEmail == null ||
            n.targetAccountEmail == currentAccountEmail;
      }).toList();
  int unreadCountFor(Role r) =>
      notificationsFor(r).where((n) => !n.read).length;

  List<PatientSuggestion> suggestionsForPatient(String patientId) =>
      suggestions.where((s) => s.patientId == patientId).toList();

  List<PatientSuggestion> suggestionsForPatientAndDoctor(
          String patientId, String doctorEmail) =>
      suggestions
          .where((s) =>
              s.patientId == patientId &&
              (s.doctorEmail == null || s.doctorEmail == doctorEmail))
          .toList();

  List<PatientSuggestion> get caregiverSuggestions {
    final patientId = linkedCaregiverPatientId;
    if (patientId.isEmpty) return const [];
    return suggestionsForPatient(patientId);
  }

  List<VisitNote> visitNotesForPatient(String patientId) =>
      visitNotes.where((note) => note.patientId == patientId).toList();

  List<VisitNote> visitNotesForPatientAndDoctor(
          String patientId, String doctorEmail) =>
      visitNotes
          .where((note) =>
              note.patientId == patientId && note.doctorEmail == doctorEmail)
          .toList();

  List<StoredAccount> get doctorAccounts =>
      storedAccounts.where((account) => account.role == Role.doctor).toList();

  PatientDoctorAssignment? assignmentForPatient(String patientId) {
    try {
      return assignments.lastWhere((a) => a.patientId == patientId);
    } catch (_) {
      return null;
    }
  }

  List<PatientDoctorAssignment> assignmentsForPatient(String patientId) =>
      assignments.where((a) => a.patientId == patientId).toList();

  List<String> assignedDoctorEmailsForPatient(String patientId) =>
      assignmentsForPatient(patientId)
          .map((assignment) => assignment.doctorEmail)
          .toSet()
          .toList();

  StoredAccount? doctorForPatient(String patientId) {
    final assignment = assignmentForPatient(patientId);
    if (assignment == null) return null;
    try {
      return storedAccounts.firstWhere(
        (account) =>
            account.role == Role.doctor &&
            account.email == assignment.doctorEmail,
      );
    } catch (_) {
      return null;
    }
  }

  String assignedDoctorNameForPatient(String patientId) {
    final doctor = doctorForPatient(patientId);
    if (doctor == null) return '';
    final last = _lastName(doctor.name);
    if (last.isEmpty) return doctor.name;
    return 'Dr. ${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
  }

  List<StoredAccount> doctorsForPatient(String patientId) {
    final emails = assignmentsForPatient(patientId)
        .map((assignment) => assignment.doctorEmail)
        .toSet();
    return storedAccounts
        .where((account) =>
            account.role == Role.doctor && emails.contains(account.email))
        .toList();
  }

  String doctorDisplayNameForAccount(StoredAccount doctor) {
    final last = _lastName(doctor.name);
    if (last.isEmpty) return doctor.name;
    return 'Dr. ${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
  }

  String doctorDisplayNameForEmail(String doctorEmail) {
    try {
      final doctor = storedAccounts.firstWhere((account) =>
          account.role == Role.doctor && account.email == doctorEmail);
      return doctorDisplayNameForAccount(doctor);
    } catch (_) {
      return doctorEmail;
    }
  }

  String assignedDoctorNamesForPatient(String patientId) {
    final names = doctorsForPatient(patientId)
        .map(doctorDisplayNameForAccount)
        .where((name) => name.isNotEmpty)
        .toList();
    return names.join(', ');
  }

  String caregiverNameForPatient(String patientId) {
    try {
      return storedAccounts
          .firstWhere((account) =>
              account.role == Role.caregiver &&
              account.linkedPatientId == patientId)
          .name;
    } catch (_) {
      return 'Not linked';
    }
  }

  List<StoredAccount> caregiversForPatient(String patientId) => storedAccounts
      .where((account) =>
          account.role == Role.caregiver && account.linkedPatientId == patientId)
      .toList();

  List<String> caregiverEmailsForPatient(String patientId) =>
      caregiversForPatient(patientId).map((account) => account.email).toList();

  int patientLoadForDoctor(String doctorEmail) =>
      assignments.where((a) => a.doctorEmail == doctorEmail).length;

  bool isDoctorAvailable(String doctorEmail) =>
      !unavailableDoctorEmails.contains(doctorEmail);

  List<PatientProfile> assignedPatientsForDoctor(String doctorEmail) {
    final assignedIds = assignments
        .where((a) => a.doctorEmail == doctorEmail)
        .map((a) => a.patientId)
        .toSet();
    return patients
        .where((patient) => assignedIds.contains(patient.id))
        .toList();
  }

  List<PatientProfile> get doctorVisiblePatients {
    if (role != Role.doctor || currentAccountEmail.isEmpty) return patients;
    return assignedPatientsForDoctor(currentAccountEmail);
  }

  List<CaregiverContact> get doctorVisibleCaregiverContacts {
    if (role != Role.doctor || currentAccountEmail.isEmpty) {
      return caregiverContacts;
    }

    final assignedIds = assignedPatientsForDoctor(currentAccountEmail)
        .map((patient) => patient.id)
        .toSet();
    final contacts = <CaregiverContact>[];
    final seenPatientIds = <String>{};

    for (final account
        in storedAccounts.where((a) => a.role == Role.caregiver)) {
      final patientId = account.linkedPatientId ?? '';
      if (!assignedIds.contains(patientId) ||
          seenPatientIds.contains(patientId)) {
        continue;
      }
      seenPatientIds.add(patientId);
      contacts.add(CaregiverContact(
        id: account.email,
        name: account.name,
        shortName: _firstName(account.name),
        initials: _initialsFor(account.name, fallback: 'C'),
        avatarColor: 0xFF059669,
        patientName: _patientNameForId(patientId) ?? 'Linked patient',
      ));
    }

    return contacts;
  }

  List<AppointmentSlot> get doctorScopedSlots {
    if (role != Role.doctor || currentAccountEmail.isEmpty) return slots;
    return slots.where(_slotBelongsToCurrentDoctor).toList();
  }

  List<AppointmentSlot> get publishedAvailableSlotsForAssignedDoctors {
    final patientId = _activePatientIdForCurrentUser;
    if (patientId.isEmpty) return const [];
    final doctorEmails = assignedDoctorEmailsForPatient(patientId).toSet();
    return slots
        .where((slot) =>
            slot.status == SlotStatus.available &&
            slot.published &&
            doctorEmails.contains(slot.doctorId))
        .toList();
  }

  Map<String, List<AppointmentSlot>> slotsByDoctor(
      Iterable<AppointmentSlot> source) {
    final grouped = <String, List<AppointmentSlot>>{};
    for (final slot in source) {
      grouped.putIfAbsent(slot.doctorId, () => []).add(slot);
    }
    return grouped;
  }

  List<AppointmentSlot> get _visiblePatientSlots {
    if (role == Role.doctor) return doctorScopedSlots;
    final patientId = _activePatientIdForCurrentUser;
    if (patientId.isEmpty) return const [];
    return slots.where((slot) => slot.patientId == patientId).toList();
  }

  String get _activePatientIdForCurrentUser {
    if (role == Role.caregiver) return linkedCaregiverPatientId;
    if (generatedPatientId.isNotEmpty) return generatedPatientId;
    if (selectedPatientId.isNotEmpty) return selectedPatientId;
    return selectedPatient?.id ?? '';
  }

  bool _slotBelongsToCurrentDoctor(AppointmentSlot slot) {
    return slot.doctorId == currentAccountEmail;
  }

  String? _caregiverEmailForSlot(AppointmentSlot slot) {
    if (slot.caregiverEmail != null && slot.caregiverEmail!.isNotEmpty) {
      return slot.caregiverEmail;
    }
    final patientId = slot.patientId;
    if (patientId == null || patientId.isEmpty || slot.caregiverId == null) {
      return null;
    }
    final matches = caregiversForPatient(patientId)
        .where((account) => _firstName(account.name) == slot.caregiverId)
        .toList();
    return matches.length == 1 ? matches.first.email : null;
  }

  void _notifyBookingCaregiver(AppointmentSlot slot, String text) {
    final caregiverEmail = _caregiverEmailForSlot(slot);
    if (caregiverEmail == null) return;
    pushNotification(text, Role.caregiver, targetAccountEmail: caregiverEmail);
  }

  void _notifyCaregiversForPatient(String patientId, String text) {
    for (final caregiverEmail in caregiverEmailsForPatient(patientId)) {
      pushNotification(text, Role.caregiver, targetAccountEmail: caregiverEmail);
    }
  }

  String? assignedDoctorEmailForPatient(String patientId) =>
      assignmentForPatient(patientId)?.doctorEmail;

  String? get assignedDoctorEmailForCurrentCaregiver {
    final patientId = linkedCaregiverPatientId;
    if (patientId.isEmpty) return null;
    return assignedDoctorEmailForPatient(patientId);
  }

  String _docCgThreadKey(String caregiverEmail, {String? doctorEmail}) {
    final resolvedDoctorEmail = doctorEmail ??
        (role == Role.caregiver
            ? assignedDoctorEmailForCurrentCaregiver
            : currentAccountEmail);
    if (resolvedDoctorEmail == null || resolvedDoctorEmail.isEmpty) {
      return caregiverEmail;
    }
    return '$resolvedDoctorEmail::$caregiverEmail';
  }

  String _patientDoctorThreadKey(String patientId, {String? doctorEmail}) {
    final resolvedDoctorEmail = doctorEmail ??
        (role == Role.doctor
            ? currentAccountEmail
            : assignedDoctorEmailForPatient(patientId));
    if (resolvedDoctorEmail == null || resolvedDoctorEmail.isEmpty) {
      return patientId;
    }
    return '$resolvedDoctorEmail::$patientId';
  }

  List<ChatMessage> doctorCaregiverThread(String caregiverEmail) =>
      docCgThreads[_docCgThreadKey(caregiverEmail)] ?? const [];

  List<ChatMessage> caregiverDoctorThreadFor(String doctorEmail) {
    if (currentAccountEmail.isEmpty) return const [];
    return docCgThreads[_docCgThreadKey(
          currentAccountEmail,
          doctorEmail: doctorEmail,
        )] ??
        const [];
  }

  List<ChatMessage> patientDoctorThread(String patientId, String doctorEmail) =>
      patientMessages[
          _patientDoctorThreadKey(patientId, doctorEmail: doctorEmail)] ??
       const [];

  String _caregiverPatientThreadKey(String patientId, {String? caregiverEmail}) {
    final resolvedCaregiverEmail = caregiverEmail ??
        (role == Role.caregiver ? currentAccountEmail : null);
    if (resolvedCaregiverEmail == null || resolvedCaregiverEmail.isEmpty) {
      return patientId;
    }
    return '$resolvedCaregiverEmail::$patientId';
  }

  List<ChatMessage> caregiverPatientThread(String patientId,
          {String? caregiverEmail}) =>
      caregiverPatientThreads[
          _caregiverPatientThreadKey(patientId, caregiverEmail: caregiverEmail)] ??
      const [];

  void selectPatient(String patientId) {
    selectedPatientId = patientId;
    notifyListeners();
  }

  void assignDoctorToPatient(String patientId, String doctorEmail) {
    if (patientId.isEmpty || doctorEmail.isEmpty) return;
    final alreadyAssigned = assignments.any((assignment) =>
        assignment.patientId == patientId &&
        assignment.doctorEmail == doctorEmail);
    if (alreadyAssigned) return;
    assignments.add(PatientDoctorAssignment(
      id: newId(),
      patientId: patientId,
      doctorEmail: doctorEmail,
      assignedAt: DateFormat('MMM d, y - h:mm a').format(DateTime.now()),
    ));
    _syncPatientLinks();
    unawaited(_saveAssignments());
    pushNotification('A patient has been assigned to your care.', Role.doctor,
        targetAccountEmail: doctorEmail);
    pushNotification('Your clinic assigned a doctor.', Role.patient);
    _notifyCaregiversForPatient(
        patientId, 'Your patient has a clinic doctor assignment.');
    notifyListeners();
  }

  void removeDoctorFromPatient(String patientId, String doctorEmail) {
    if (patientId.isEmpty || doctorEmail.isEmpty) return;
    assignments.removeWhere((assignment) =>
        assignment.patientId == patientId &&
        assignment.doctorEmail == doctorEmail);
    _syncPatientLinks();
    unawaited(_saveAssignments());
    notifyListeners();
  }

  void toggleDoctorAvailability(String doctorEmail) {
    if (unavailableDoctorEmails.contains(doctorEmail)) {
      unavailableDoctorEmails.remove(doctorEmail);
    } else {
      unavailableDoctorEmails.add(doctorEmail);
    }
    unawaited(_saveDoctorAvailability());
    notifyListeners();
  }

  String cancellationSourceLabel(AppointmentSlot slot) {
    if (slot.status != SlotStatus.cancelled) return '';
    final hasCaregiverCancellation = slot.log.any((entry) =>
        entry.role == 'caregiver' &&
        entry.action.toLowerCase().contains('cancell'));
    if (hasCaregiverCancellation) return 'Cancelled by caregiver';

    final hasDoctorCancellation = slot.log.any((entry) =>
        entry.role == 'doctor' &&
        entry.action.toLowerCase().contains('cancell'));
    if (hasDoctorCancellation) return 'Cancelled by doctor';

    return 'Cancelled';
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _currentPatientMoodKey {
    if (generatedPatientId.isNotEmpty) return generatedPatientId;
    if (selectedPatientId.isNotEmpty) return selectedPatientId;
    return currentAccountEmail;
  }

  bool get shouldShowMoodCheck {
    final patientKey = _currentPatientMoodKey;
    if (patientKey.isEmpty) return true;
    return _lastMoodCheckByPatient[patientKey] != _todayKey;
  }

  List<ChatMessage> get caregiverDoctorThread {
    if (currentAccountEmail.isEmpty) return const [];
    final thread = docCgThreads[_docCgThreadKey(currentAccountEmail)];
    if (thread != null && thread.isNotEmpty) return thread;
    return cgDoctorThread;
  }

  bool get alertTriggered {
    if (moodHistory.length < 3) return false;
    final last3 = moodHistory.sublist(moodHistory.length - 3);
    return last3.every((e) => e.mood <= 2);
  }

  DateTime _reminderSortValue(Reminder reminder) {
    if (reminder.dueAt != null) return reminder.dueAt!;

    final parsedDate = reminder.date.isEmpty
        ? DateTime.now()
        : DateTime.tryParse(reminder.date) ?? DateTime.now();
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false)
        .firstMatch(reminder.time);
    if (match == null) return parsedDate;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = (match.group(3) ?? '').toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return DateTime(
        parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
  }

  void signUp(StoredAccount account) {
    storedAccounts.removeWhere((a) => a.email == account.email);
    storedAccounts.add(account);
    _rebuildDirectoryFromAccounts();
    _applyAccountSession(account);
    _saveAccounts();
    notifyListeners();
  }

  StoredAccount? signIn(String email, String password) {
    try {
      final match = storedAccounts.firstWhere(
        (a) => a.email == email.trim().toLowerCase() && a.password == password,
      );
      _applyAccountSession(match);
      notifyListeners();
      return match;
    } catch (_) {
      return null;
    }
  }

  void logout() {
    session = null;
    role = null;
    currentAccountEmail = '';
    notifyListeners();
  }

  void submitMood(int mood) {
    final entry = MoodEntry(
      date: DateFormat('MMM d').format(DateTime.now()),
      mood: mood,
      label: moodLabels[mood] ?? '',
    );
    moodHistory.add(entry);
    if (selectedPatientId.isNotEmpty) {
      patientMoodData.putIfAbsent(selectedPatientId, () => []).add(entry);
    }
    final patientKey = _currentPatientMoodKey;
    if (patientKey.isNotEmpty) {
      _lastMoodCheckByPatient[patientKey] = _todayKey;
      unawaited(_saveMoodCheckDates());
    }
    notifyListeners();
  }

  void addReminder(String label, String time, {String date = ''}) {
    addMedicationReminder(label: label, date: date, time: time);
  }

  void addMedicationReminder({
    required String label,
    required String date,
    required String time,
    DateTime? dueAt,
  }) {
    final patientId = _activePatientIdForCurrentUser;
    final reminder = Reminder(
      id: newId(),
      patientId: patientId.isEmpty ? null : patientId,
      type: 'medication',
      label: label,
      date: date,
      time: time,
      dueAt: dueAt,
    );
    reminders.add(reminder);
    _scheduleMedicationNotice(reminder);
    if (patientId.isNotEmpty) {
      _notifyCaregiversForPatient(
          patientId, 'Medication reminder added: $label on $date at $time.');
    }
    pushNotification('New medicine reminder: $label at $time.', Role.patient);
    notifyListeners();
  }

  void confirmReminder(String id) {
    final r = reminders.firstWhere((r) => r.id == id);
    r.confirmed = true;
    notifyListeners();
  }

  void takeMedicationReminder(String id) {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final reminder = reminders.removeAt(index);
    _reminderTimers.remove(id)?.cancel();
    final patientId = reminder.patientId ?? _activePatientIdForCurrentUser;
    if (patientId.isNotEmpty) {
      _notifyCaregiversForPatient(patientId,
          '${patientFirstName.isEmpty ? "Patient" : patientFirstName} took ${reminder.label}.');
    }
    notifyListeners();
  }

  void undoReminder(String id) {
    final r = reminders.firstWhere((r) => r.id == id);
    r.confirmed = false;
    notifyListeners();
  }

  void _scheduleMedicationNotice(Reminder reminder) {
    _reminderTimers.remove(reminder.id)?.cancel();
    final dueAt = reminder.dueAt;
    if (dueAt == null) return;

    final notifyAt = dueAt.subtract(const Duration(minutes: 5));
    final delay = notifyAt.difference(DateTime.now());
    final effectiveDelay = delay.isNegative ? Duration.zero : delay;
    _reminderTimers[reminder.id] = Timer(effectiveDelay, () {
      if (!reminders.any((r) => r.id == reminder.id)) return;
      final message =
          '${reminder.label} is due at ${reminder.time}${reminder.date.isEmpty ? "" : " on ${reminder.date}"}.';
      pushNotification('Medicine reminder: $message', Role.patient);
      final patientId = reminder.patientId ?? _activePatientIdForCurrentUser;
      if (patientId.isNotEmpty) {
        _notifyCaregiversForPatient(
            patientId, 'Patient medicine reminder: $message');
      }
      NotificationService.instance.showLocalNotification(
        id: reminder.id.hashCode,
        title: 'Medicine reminder',
        body: message,
      );
    });
  }

  void addSuggestion(PatientSuggestion s) {
    suggestions.add(PatientSuggestion(
      id: s.id,
      patientId: s.patientId,
      doctorEmail: s.doctorEmail ?? currentAccountEmail,
      type: s.type,
      text: s.text,
      rationale: s.rationale,
      priority: s.priority,
      from: s.from,
    ));
    notifyListeners();
  }

  void addVisitNote(String text, {required String doctorEmail}) {
    final patientId = linkedCaregiverPatientId.isNotEmpty
        ? linkedCaregiverPatientId
        : selectedPatientId;
    if (patientId.isEmpty || doctorEmail.isEmpty) return;
    visitNotes.add(VisitNote(
      id: newId(),
      patientId: patientId,
      doctorEmail: doctorEmail,
      note: text,
      timestamp:
          '${DateFormat('MMM d, y').format(DateTime.now())} - ${nowTime()}',
      from: session?.name ?? 'Caregiver',
    ));
    pushNotification(
        '${caregiverFirstName.isEmpty ? "Caregiver" : caregiverFirstName} published a visit note.',
        Role.doctor,
        targetAccountEmail: doctorEmail);
    notifyListeners();
  }

  void pushNotification(String text, Role targetRole,
      {String? targetAccountEmail}) {
    notifications.add(AppNotification(
      id: newId(),
      text: text,
      time: nowTime(),
      role: targetRole,
      targetAccountEmail: targetAccountEmail,
    ));
    notifyListeners();
  }

  void markNotificationsRead(Role r) {
    for (final n in notificationsFor(r)) {
      n.read = true;
    }
    notifyListeners();
  }

  void sendPatientMessage(String patientId, String text, String from, Role role,
      {String? doctorEmail}) {
    final threadKey = _patientDoctorThreadKey(patientId,
        doctorEmail:
            doctorEmail ?? (role == Role.doctor ? currentAccountEmail : null));
    patientMessages.putIfAbsent(threadKey, () => []).add(ChatMessage(
          id: newId(),
          from: from,
          text: text,
          time: nowTime(),
          role: role,
        ));
    notifyListeners();
  }

  void sendDocCgMessage(String cgId, String text, String from) {
    final threadKey = _docCgThreadKey(cgId);
    docCgThreads.putIfAbsent(threadKey, () => []).add(ChatMessage(
          id: newId(),
          from: from,
          text: text,
          time: nowTime(),
          role: Role.doctor,
        ));
    notifyListeners();
  }

  void sendCgDoctorMessage(String text, String from, {String? doctorEmail}) {
    final cgId = currentAccountEmail;
    if (cgId.isEmpty) return;
    final thread = docCgThreads.putIfAbsent(
        _docCgThreadKey(cgId, doctorEmail: doctorEmail), () => []);
    if (thread.isEmpty && cgDoctorThread.isNotEmpty) {
      thread.addAll(cgDoctorThread);
    }
    thread.add(ChatMessage(
      id: newId(),
      from: from,
      text: text,
      time: nowTime(),
      role: Role.caregiver,
    ));
    notifyListeners();
  }

  void sendCgPatientMessage(String text, String from) {
    final patientId = linkedCaregiverPatientId;
    if (patientId.isEmpty || currentAccountEmail.isEmpty) return;
    caregiverPatientThreads
        .putIfAbsent(_caregiverPatientThreadKey(patientId), () => [])
        .add(ChatMessage(
        id: newId(),
        from: from,
        text: text,
        time: nowTime(),
        role: Role.caregiver));
    notifyListeners();
  }

  void sendPatientCaregiverMessage(String text, String from,
      {required String caregiverEmail}) {
    final patientId = _activePatientIdForCurrentUser;
    if (patientId.isEmpty) return;
    caregiverPatientThreads
        .putIfAbsent(
            _caregiverPatientThreadKey(patientId, caregiverEmail: caregiverEmail),
            () => [])
        .add(ChatMessage(
        id: newId(),
        from: from,
        text: text,
        time: nowTime(),
        role: Role.patient));
    notifyListeners();
  }

  bool checkConflict(String date, String time, {String? excludeId}) {
    return slots.any((s) {
      if (s.id == excludeId) return false;
      if (s.date != date) return false;
      if (![
        SlotStatus.confirmed,
        SlotStatus.pendingDoctor,
        SlotStatus.pendingCaregiver,
        SlotStatus.pendingCancellation
      ].contains(s.status)) {
        return false;
      }
      return s.time == time;
    });
  }

  void addSlot({
    required String date,
    required String time,
    required int duration,
    required String title,
    FollowUpSchedule? followUp,
  }) {
    final slot = AppointmentSlot(
      id: newId(),
      doctorId: currentAccountEmail.isNotEmpty
          ? currentAccountEmail
          : (session?.name ?? 'doctor'),
      date: date,
      time: time,
      duration: duration,
      title: title.isEmpty ? 'Appointment' : title,
      followUpSchedule: followUp,
    );
    slot.addLog('Slot created', doctorDisplayName, 'doctor');
    slots.add(slot);
    notifyListeners();
  }

  void togglePublish(String id) {
    final s = slots.firstWhere((s) => s.id == id);
    s.published = !s.published;
    s.addLog(s.published ? 'Slot published' : 'Slot unpublished',
        doctorDisplayName, 'doctor');
    notifyListeners();
  }

  void approveSlot(String id) {
    final s = slots.firstWhere((s) => s.id == id);
    s.status = SlotStatus.confirmed;
    s.escalated = false;
    s.addLog('Booking approved', doctorDisplayName, 'doctor');
    _notifyBookingCaregiver(
        s, 'Your booking request has been approved by $doctorDisplayName.');
    pushNotification('Your appointment has been confirmed.', Role.patient);
    notifyListeners();
  }

  void declineSlot(String id, String reason) {
    final s = slots.firstWhere((s) => s.id == id);
    s.status = SlotStatus.available;
    s.cancelReason = reason;
    s.escalated = false;
    s.addLog('Booking declined', doctorDisplayName, 'doctor', note: reason);
    _notifyBookingCaregiver(s,
        'Your booking request was declined by $doctorDisplayName. Reason: $reason');
    s.caregiverId = null;
    s.caregiverEmail = null;
    s.patientId = null;
    notifyListeners();
  }

  void cancelSlotDoctor(String id, String reason) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) return;
    final s = slots.firstWhere((s) => s.id == id);
    s.status = SlotStatus.cancelled;
    s.escalated = false;
    s.cancelReason = cleanReason;
    s.addLog('Appointment cancelled by doctor', doctorDisplayName, 'doctor',
        note: cleanReason);
    _notifyBookingCaregiver(s,
        'Your appointment has been cancelled by $doctorDisplayName. Reason: $cleanReason');
    pushNotification(
        'Your appointment has been cancelled. Reason: $cleanReason',
        Role.patient);
    notifyListeners();
  }

  void approveCancellationRequest(String id) {
    final s = slots.firstWhere((s) => s.id == id);
    final replacement = AppointmentSlot(
      id: newId(),
      doctorId: s.doctorId,
      date: s.date,
      time: s.time,
      duration: s.duration,
      title: s.title,
      followUpSchedule: s.followUpSchedule,
      status: SlotStatus.available,
      published: true,
      seriesId: s.seriesId,
    );
    replacement.caregiverId = null;
    replacement.patientId = null;
    replacement.addLog('Slot reopened after cancellation approval',
        doctorDisplayName, 'doctor');

    s.status = SlotStatus.cancelled;
    s.escalated = false;
    s.published = false;
    s.addLog('Cancellation approved', doctorDisplayName, 'doctor',
        note: s.cancelReason);
    slots.add(replacement);
    _notifyBookingCaregiver(s,
        'Your cancellation request for ${s.date} at ${s.time} was approved by $doctorDisplayName. Reason: ${s.cancelReason ?? "No reason provided."}');
    pushNotification(
        'Your appointment on ${s.date} at ${s.time} has been cancelled. Reason: ${s.cancelReason ?? "No reason provided."}',
        Role.patient);
    notifyListeners();
  }

  void declineCancellationRequest(String id, String reason) {
    final s = slots.firstWhere((s) => s.id == id);
    s.status = SlotStatus.confirmed;
    s.escalated = false;
    s.addLog('Cancellation request declined', doctorDisplayName, 'doctor',
        note: reason);
    _notifyBookingCaregiver(s,
        'Your cancellation request for ${s.date} at ${s.time} was declined by $doctorDisplayName. Reason: $reason');
    notifyListeners();
  }

  void modifySlot(String id, String newDate, String newTime) {
    if (checkConflict(newDate, newTime, excludeId: id)) return;
    final s = slots.firstWhere((s) => s.id == id);
    s.date = newDate;
    s.time = newTime;
    s.addLog('Slot modified', doctorDisplayName, 'doctor');
    _notifyBookingCaregiver(
        s, '$doctorDisplayName modified your appointment to $newDate at $newTime.');
    pushNotification(
        'Your appointment has been updated to $newDate at $newTime.',
        Role.patient);
    notifyListeners();
  }

  void requestBooking(String slotId) {
    final s = slots.firstWhere((s) => s.id == slotId);
    final patientId = linkedCaregiverPatientId.isNotEmpty
        ? linkedCaregiverPatientId
        : (patients.isNotEmpty ? patients.first.id : '');
    s.status = SlotStatus.pendingDoctor;
    s.caregiverId = caregiverFirstName;
    s.caregiverEmail = currentAccountEmail;
    s.patientId = patientId;
    s.addLog('Booking requested by caregiver', caregiverFirstName, 'caregiver');
    pushNotification(
        'Booking request from $caregiverFirstName for patient on ${s.date} at ${s.time}. Awaiting your approval.',
        Role.doctor,
        targetAccountEmail: s.doctorId);
    notifyListeners();
  }

  void confirmCaregiverSlot(String slotId) {
    final s = slots.firstWhere((s) => s.id == slotId);
    s.status = SlotStatus.pendingDoctor;
    s.addLog('Caregiver confirmed slot', caregiverFirstName, 'caregiver');
    pushNotification(
        '$caregiverFirstName confirmed a slot and it awaits your final approval.',
        Role.doctor,
        targetAccountEmail: s.doctorId);
    notifyListeners();
  }

  void suggestDifferentTime(String slotId, String note) {
    final s = slots.firstWhere((s) => s.id == slotId);
    s.approvalNote = note;
    s.addLog(
        'Caregiver suggested different time', caregiverFirstName, 'caregiver',
        note: note);
    pushNotification(
        '$caregiverFirstName suggested a different time for slot on ${s.date}. Note: $note',
        Role.doctor,
        targetAccountEmail: s.doctorId);
    notifyListeners();
  }

  void cancelSlotCaregiver(String slotId, String reason, bool isUrgent) {
    final s = slots.firstWhere((s) => s.id == slotId);
    if (isUrgent) {
      s.status = SlotStatus.pendingCancellation;
      s.escalated = true;
      s.cancelReason = reason;
      s.addLog('Cancellation requested (< 24h, escalated to doctor)',
          caregiverFirstName, 'caregiver',
          note: reason);
      pushNotification(
          'Cancellation approval request from $caregiverFirstName for appointment on ${s.date} at ${s.time}. Reason: $reason',
          Role.doctor,
          targetAccountEmail: s.doctorId);
    } else {
      s.status = SlotStatus.cancelled;
      s.cancelReason = reason;
      s.escalated = false;
      s.published = false;
      s.addLog(
          'Appointment cancelled by caregiver', caregiverFirstName, 'caregiver',
          note: reason);
      final replacement = AppointmentSlot(
        id: newId(),
        doctorId: s.doctorId,
        date: s.date,
        time: s.time,
        duration: s.duration,
        title: s.title,
        followUpSchedule: s.followUpSchedule,
        status: SlotStatus.available,
        published: true,
        seriesId: s.seriesId,
      );
      replacement.caregiverId = null;
      replacement.patientId = null;
      replacement.addLog('Slot reopened after caregiver cancellation',
          caregiverFirstName, 'caregiver');
      slots.add(replacement);
      pushNotification(
          '$caregiverFirstName cancelled the appointment on ${s.date}. Reason: $reason',
          Role.doctor,
          targetAccountEmail: s.doctorId);
      pushNotification(
          'Your appointment on ${s.date} has been cancelled. Reason: $reason.',
          Role.patient);
    }
    notifyListeners();
  }

  void seedDemoData() {}
}

final appStateProvider = ChangeNotifierProvider<AppState>((ref) => AppState());
