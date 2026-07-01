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
  final List<ChatMessage> cgPatientThread = [];
  final List<Reminder> reminders = [];
  final List<PatientSuggestion> suggestions = [];
  final List<VisitNote> visitNotes = [];
  final List<AppointmentSlot> slots = [];
  final List<AppNotification> notifications = [];

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
    try {
      final doc = storedAccounts.firstWhere((a) => a.role == Role.doctor);
      final last = _lastName(doc.name);
      linkedDoctorName =
          'Dr. ${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
    } catch (_) {
      linkedDoctorName = '';
    }
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
    try {
      return patients.firstWhere((p) => p.id == selectedPatientId);
    } catch (_) {
      return patients.isNotEmpty ? patients.first : null;
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
  List<AppointmentSlot> get awaitingApprovalSlots => slots
      .where((s) => s.status == SlotStatus.pendingDoctor && !s.escalated)
      .toList();
  List<AppointmentSlot> get cancellationApprovalSlots =>
      slots.where((s) => s.status == SlotStatus.pendingCancellation).toList();
  List<AppointmentSlot> get confirmedSlots =>
      slots.where((s) => s.status == SlotStatus.confirmed).toList();
  List<AppointmentSlot> get cancelledSlots =>
      slots.where((s) => s.status == SlotStatus.cancelled).toList();
  List<AppointmentSlot> get slotsPendingCaregiver =>
      slots.where((s) => s.status == SlotStatus.pendingCaregiver).toList();
  List<Reminder> get medicationReminders {
    final list = reminders.where((r) => r.type == 'medication').toList();
    list.sort((a, b) => _reminderSortValue(a).compareTo(_reminderSortValue(b)));
    return list;
  }

  List<AppNotification> notificationsFor(Role r) =>
      notifications.where((n) => n.role == r).toList();
  int unreadCountFor(Role r) =>
      notificationsFor(r).where((n) => !n.read).length;

  List<PatientSuggestion> suggestionsForPatient(String patientId) =>
      suggestions.where((s) => s.patientId == patientId).toList();

  List<PatientSuggestion> get caregiverSuggestions {
    final patientId = linkedCaregiverPatientId;
    if (patientId.isEmpty) return const [];
    return suggestionsForPatient(patientId);
  }

  List<VisitNote> visitNotesForPatient(String patientId) =>
      visitNotes.where((note) => note.patientId == patientId).toList();

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
    final thread = docCgThreads[currentAccountEmail];
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
    final reminder = Reminder(
      id: newId(),
      type: 'medication',
      label: label,
      date: date,
      time: time,
      dueAt: dueAt,
    );
    reminders.add(reminder);
    _scheduleMedicationNotice(reminder);
    pushNotification(
        'Medication reminder added: $label on $date at $time.', Role.caregiver);
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
    pushNotification(
        '${patientFirstName.isEmpty ? "Patient" : patientFirstName} took ${reminder.label}.',
        Role.caregiver);
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
      pushNotification('Patient medicine reminder: $message', Role.caregiver);
      NotificationService.instance.showLocalNotification(
        id: reminder.id.hashCode,
        title: 'Medicine reminder',
        body: message,
      );
    });
  }

  void addSuggestion(PatientSuggestion s) {
    suggestions.add(s);
    notifyListeners();
  }

  void addVisitNote(String text) {
    final patientId = linkedCaregiverPatientId.isNotEmpty
        ? linkedCaregiverPatientId
        : selectedPatientId;
    if (patientId.isEmpty) return;
    visitNotes.add(VisitNote(
      id: newId(),
      patientId: patientId,
      note: text,
      timestamp:
          '${DateFormat('MMM d, y').format(DateTime.now())} - ${nowTime()}',
      from: session?.name ?? 'Caregiver',
    ));
    pushNotification(
        '${caregiverFirstName.isEmpty ? "Caregiver" : caregiverFirstName} published a visit note.',
        Role.doctor);
    notifyListeners();
  }

  void pushNotification(String text, Role targetRole) {
    notifications.add(AppNotification(
      id: newId(),
      text: text,
      time: nowTime(),
      role: targetRole,
    ));
    notifyListeners();
  }

  void markNotificationsRead(Role r) {
    for (final n in notificationsFor(r)) {
      n.read = true;
    }
    notifyListeners();
  }

  void sendPatientMessage(
      String patientId, String text, String from, Role role) {
    patientMessages.putIfAbsent(patientId, () => []).add(ChatMessage(
          id: newId(),
          from: from,
          text: text,
          time: nowTime(),
          role: role,
        ));
    notifyListeners();
  }

  void sendDocCgMessage(String cgId, String text, String from) {
    docCgThreads.putIfAbsent(cgId, () => []).add(ChatMessage(
          id: newId(),
          from: from,
          text: text,
          time: nowTime(),
          role: Role.doctor,
        ));
    notifyListeners();
  }

  void sendCgDoctorMessage(String text, String from) {
    final cgId = currentAccountEmail;
    if (cgId.isEmpty) return;
    final thread = docCgThreads.putIfAbsent(cgId, () => []);
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
    cgPatientThread.add(ChatMessage(
        id: newId(),
        from: from,
        text: text,
        time: nowTime(),
        role: Role.caregiver));
    notifyListeners();
  }

  void sendPatientCaregiverMessage(String text, String from) {
    cgPatientThread.add(ChatMessage(
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
      doctorId: session?.name ?? 'doctor',
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
    pushNotification(
        'Your booking request has been approved by $doctorDisplayName.',
        Role.caregiver);
    pushNotification('Your appointment has been confirmed.', Role.patient);
    notifyListeners();
  }

  void declineSlot(String id, String reason) {
    final s = slots.firstWhere((s) => s.id == id);
    s.status = SlotStatus.available;
    s.cancelReason = reason;
    s.escalated = false;
    s.caregiverId = null;
    s.patientId = null;
    s.addLog('Booking declined', doctorDisplayName, 'doctor', note: reason);
    pushNotification(
        'Your booking request was declined by $doctorDisplayName. Reason: $reason',
        Role.caregiver);
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
    pushNotification(
        'Your appointment has been cancelled by $doctorDisplayName. Reason: $cleanReason',
        Role.caregiver);
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
    pushNotification(
        'Your cancellation request for ${s.date} at ${s.time} was approved by $doctorDisplayName. Reason: ${s.cancelReason ?? "No reason provided."}',
        Role.caregiver);
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
    pushNotification(
        'Your cancellation request for ${s.date} at ${s.time} was declined by $doctorDisplayName. Reason: $reason',
        Role.caregiver);
    notifyListeners();
  }

  void modifySlot(String id, String newDate, String newTime) {
    if (checkConflict(newDate, newTime, excludeId: id)) return;
    final s = slots.firstWhere((s) => s.id == id);
    s.date = newDate;
    s.time = newTime;
    s.addLog('Slot modified', doctorDisplayName, 'doctor');
    pushNotification(
        '$doctorDisplayName modified your appointment to $newDate at $newTime.',
        Role.caregiver);
    pushNotification(
        'Your appointment has been updated to $newDate at $newTime.',
        Role.patient);
    notifyListeners();
  }

  void requestBooking(String slotId) {
    final s = slots.firstWhere((s) => s.id == slotId);
    final patientId = patients.isNotEmpty ? patients.first.id : '';
    s.status = SlotStatus.pendingDoctor;
    s.caregiverId = caregiverFirstName;
    s.patientId = patientId;
    s.addLog('Booking requested by caregiver', caregiverFirstName, 'caregiver');
    pushNotification(
        'Booking request from $caregiverFirstName for patient on ${s.date} at ${s.time}. Awaiting your approval.',
        Role.doctor);
    notifyListeners();
  }

  void confirmCaregiverSlot(String slotId) {
    final s = slots.firstWhere((s) => s.id == slotId);
    s.status = SlotStatus.pendingDoctor;
    s.addLog('Caregiver confirmed slot', caregiverFirstName, 'caregiver');
    pushNotification(
        '$caregiverFirstName confirmed a slot and it awaits your final approval.',
        Role.doctor);
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
        Role.doctor);
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
          Role.doctor);
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
          Role.doctor);
      pushNotification(
          'Your appointment on ${s.date} has been cancelled. Reason: $reason.',
          Role.patient);
    }
    notifyListeners();
  }

  void seedDemoData() {}
}

final appStateProvider = ChangeNotifierProvider<AppState>((ref) => AppState());
