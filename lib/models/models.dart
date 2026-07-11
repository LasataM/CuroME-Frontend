import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4().substring(0, 8);

enum Role { doctor, caregiver, patient, clinicAdmin }

Role roleFromString(String s) =>
    Role.values.firstWhere((r) => r.name == s, orElse: () => Role.patient);

enum SlotStatus {
  available,
  pendingCaregiver,
  pendingDoctor,
  pendingCancellation,
  confirmed,
  cancelled,
  completed,
}

const Map<SlotStatus, String> slotStatusLabel = {
  SlotStatus.available: 'Available',
  SlotStatus.pendingCaregiver: 'Pending Caregiver',
  SlotStatus.pendingDoctor: 'Pending Doctor',
  SlotStatus.pendingCancellation: 'Pending Cancellation',
  SlotStatus.confirmed: 'Confirmed',
  SlotStatus.cancelled: 'Cancelled',
  SlotStatus.completed: 'Completed',
};

enum Priority { low, medium, high }

enum FollowUpSchedule { weekly, fortnightly, monthly, custom }

class AuditLogEntry {
  final String action;
  final String by;
  final String role;
  final String at;
  final String? note;

  AuditLogEntry({
    required this.action,
    required this.by,
    required this.role,
    required this.at,
    this.note,
  });
}

class AppointmentSlot {
  final String id;
  final String doctorId;
  String date;
  String time;
  int duration;
  SlotStatus status;
  String? patientId;
  String? caregiverId;
  String? title;
  FollowUpSchedule? followUpSchedule;
  String? cancelReason;
  String? approvalNote;
  bool published;
  String? seriesId;
  bool escalated;
  List<AuditLogEntry> log;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    this.duration = 30,
    this.status = SlotStatus.available,
    this.patientId,
    this.caregiverId,
    this.title,
    this.followUpSchedule,
    this.cancelReason,
    this.approvalNote,
    this.published = false,
    this.seriesId,
    this.escalated = false,
    List<AuditLogEntry>? log,
  }) : log = log ?? [];

  void addLog(String action, String by, String role, {String? note}) {
    log.add(AuditLogEntry(
      action: action,
      by: by,
      role: role,
      at: DateTime.now().toString(),
      note: note,
    ));
  }
}

class AppNotification {
  final String id;
  final String text;
  final String time;
  bool read;
  final Role role;
  final String? targetAccountEmail;

  AppNotification({
    required this.id,
    required this.text,
    required this.time,
    this.read = false,
    required this.role,
    this.targetAccountEmail,
  });
}

class Session {
  final bool loggedIn;
  final Role role;
  final String name;
  Session({required this.loggedIn, required this.role, required this.name});
}

class StoredAccount {
  final String email;
  final String password;
  final Role role;
  final String name;
  final int? age;
  final String? gender;
  final String? phone;
  final String? specialization;
  final String? licenseNumber;
  final String? linkedPatientId;
  final String? patientId;

  StoredAccount({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.specialization,
    this.licenseNumber,
    this.linkedPatientId,
    this.patientId,
  });

  /// Converts this model to a JSON map for the FastAPI /auth/register endpoint.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role.name, // Converts enum (e.g., Role.doctor) to string ('doctor')
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'specialization': specialization,
      'licenseNumber': licenseNumber, // Matches alias in backend schemas.py
      'linkedPatientId': linkedPatientId, // Matches alias in backend schemas.py
      'patientId': patientId,
    };
  }
}

class PatientDoctorAssignment {
  final String id;
  final String patientId;
  final String doctorEmail;
  final String assignedAt;

  PatientDoctorAssignment({
    required this.id,
    required this.patientId,
    required this.doctorEmail,
    required this.assignedAt,
  });
}

class PatientProfile {
  final String id;
  final String name;
  final String shortName;
  final String initials;
  final int avatarColor; // ARGB int

  PatientProfile({
    required this.id,
    required this.name,
    required this.shortName,
    required this.initials,
    required this.avatarColor,
  });
}

class CaregiverContact {
  final String id;
  final String name;
  final String shortName;
  final String initials;
  final int avatarColor;
  final String patientName;

  CaregiverContact({
    required this.id,
    required this.name,
    required this.shortName,
    required this.initials,
    required this.avatarColor,
    required this.patientName,
  });
}

class MoodEntry {
  final String date;
  final int mood; // 1-5
  final String label;

  MoodEntry({required this.date, required this.mood, required this.label});
}

class AppAppointment {
  final String id;
  final String title;
  final String date;
  final String time;
  final String patient;
  String status; // upcoming | cancelled | completed

  AppAppointment({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.patient,
    this.status = 'upcoming',
  });
}

class ChatMessage {
  final String id;
  final String from;
  final String text;
  final String time;
  final Role role;
  bool isRead;

  ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.time,
    required this.role,
    this.isRead = true,
  });
}

class VisitNote {
  final String id;
  final String patientId;
  final String doctorEmail;
  final String note;
  final String timestamp;
  final String from;

  VisitNote({
    required this.id,
    required this.patientId,
    required this.doctorEmail,
    required this.note,
    required this.timestamp,
    required this.from,
  });
}

class Reminder {
  final String id;
  final String type; // medication | appointment
  final String label;
  final String date;
  final String time;
  final DateTime? dueAt;
  bool confirmed;

  Reminder({
    required this.id,
    required this.type,
    required this.label,
    this.date = '',
    required this.time,
    this.dueAt,
    this.confirmed = false,
  });
}

class PatientSuggestion {
  final String id;
  final String patientId;
  final String? doctorEmail;
  final String type; // activity | medication | followup
  final String text;
  final String rationale;
  final Priority priority;
  final String from;

  PatientSuggestion({
    required this.id,
    required this.patientId,
    this.doctorEmail,
    required this.type,
    required this.text,
    required this.rationale,
    required this.priority,
    required this.from,
  });
}

class ChatNodeOption {
  final String label;
  final String next;
  ChatNodeOption({required this.label, required this.next});
}

class ChatNode {
  final String id;
  final String text;
  final List<ChatNodeOption> options;
  ChatNode({required this.id, required this.text, this.options = const []});
}

/// Decision-tree chatbot used in the patient "Get Help" screen.
final Map<String, ChatNode> chatTree = {
  'root': ChatNode(
    id: 'root',
    text: 'Hello! I am here to help you. What do you need?',
    options: [
      ChatNodeOption(label: 'My medicine', next: 'medication'),
      ChatNodeOption(label: 'I feel upset', next: 'emotional'),
      ChatNodeOption(label: 'Call my caregiver', next: 'escalation'),
    ],
  ),
  'medication': ChatNode(
    id: 'medication',
    text: 'What do you want to know about your medicine?',
    options: [
      ChatNodeOption(label: 'What do I take?', next: 'med_list'),
      ChatNodeOption(label: 'I missed a dose', next: 'med_missed'),
      ChatNodeOption(label: 'Go back', next: 'root'),
    ],
  ),
  'med_list': ChatNode(
    id: 'med_list',
    text:
        'Please check your medicines list in the Medicines section. Always take with food and water.',
    options: [
      ChatNodeOption(label: 'Go back', next: 'medication'),
      ChatNodeOption(label: 'Home', next: 'root'),
    ],
  ),
  'med_missed': ChatNode(
    id: 'med_missed',
    text:
        'If you missed a pill, take it now if it is early. If it is nearly time for the next one, skip it. Ask your caregiver if you are unsure.',
    options: [
      ChatNodeOption(label: 'Call my caregiver', next: 'escalation'),
      ChatNodeOption(label: 'Home', next: 'root'),
    ],
  ),
  'emotional': ChatNode(
    id: 'emotional',
    text: 'I am sorry you feel that way. You are not alone. How can I help?',
    options: [
      ChatNodeOption(label: 'I feel lonely', next: 'em_lonely'),
      ChatNodeOption(label: 'I feel worried', next: 'em_anxious'),
      ChatNodeOption(label: 'Home', next: 'root'),
    ],
  ),
  'em_lonely': ChatNode(
    id: 'em_lonely',
    text:
        'It is okay to feel lonely. Your caregiver and doctor care about you very much. Would you like to call your caregiver now?',
    options: [
      ChatNodeOption(label: 'Call my caregiver', next: 'escalation'),
      ChatNodeOption(label: 'Home', next: 'root'),
    ],
  ),
  'em_anxious': ChatNode(
    id: 'em_anxious',
    text:
        'Take a slow, deep breath in through your nose. Hold it. Then breathe out slowly. You are safe. If you need help, call your caregiver.',
    options: [
      ChatNodeOption(label: 'Call my caregiver', next: 'escalation'),
      ChatNodeOption(label: 'Home', next: 'root'),
    ],
  ),
  'escalation': ChatNode(
    id: 'escalation',
    text:
        'Your caregiver will be notified right away. You can also press the big red button below for urgent help.',
    options: [
      ChatNodeOption(label: 'Return Home', next: 'root'),
    ],
  ),
};
