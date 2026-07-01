import 'package:flutter/material.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';

// ─────────────────────────────────────────────
// EmptyState
// ─────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PageHeader — sticky top bar with optional back + action
// ─────────────────────────────────────────────
class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  const PageHeader({super.key, required this.title, this.onBack, this.action});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black87),
              onPressed: onBack,
              tooltip: 'Back',
            )
          : const SizedBox.shrink(),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      centerTitle: true,
      actions: [
        if (action != null) action!,
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RoleCard — used on the login screen
// ─────────────────────────────────────────────
class RoleCard extends StatelessWidget {
  final Role role;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<Role> onSelect;

  const RoleCard({
    super.key,
    required this.role,
    required this.label,
    required this.icon,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => onSelect(role),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PatientAvatar — coloured circle with initials
// ─────────────────────────────────────────────
class PatientAvatar extends StatelessWidget {
  final PatientProfile patient;
  final double size;

  const PatientAvatar({super.key, required this.patient, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(patient.avatarColor),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        patient.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PatientSelector — horizontal scrollable pill row
// ─────────────────────────────────────────────
class PatientSelector extends StatelessWidget {
  final List<PatientProfile> patients;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const PatientSelector({
    super.key,
    required this.patients,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PATIENTS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          if (patients.isEmpty)
            const Text('No patients yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: patients.map((p) {
                  final selected = p.id == selectedId;
                  return GestureDetector(
                    onTap: () => onSelect(p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            selected ? Color(p.avatarColor) : Colors.white,
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Color(p.avatarColor).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.initials,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : Color(p.avatarColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.shortName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MoodIcon — maps 1-5 mood level to an Icon widget
// ─────────────────────────────────────────────
class MoodIcon extends StatelessWidget {
  final int mood;
  final double size;
  const MoodIcon({super.key, required this.mood, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Icon(moodIcon(mood), size: size, color: moodColors[mood]);
  }
}

// ─────────────────────────────────────────────
// StatusBadge — coloured pill for slot status
// ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final SlotStatus status;
  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case SlotStatus.available:
        return Colors.grey.shade100;
      case SlotStatus.pendingCaregiver:
        return const Color(0xFFFEF3C7);
      case SlotStatus.pendingDoctor:
        return const Color(0xFFEEF2FF);
      case SlotStatus.pendingCancellation:
        return const Color(0xFFFFEDD5);
      case SlotStatus.confirmed:
        return const Color(0xFFDCFCE7);
      case SlotStatus.cancelled:
        return const Color(0xFFFEE2E2);
      case SlotStatus.completed:
        return const Color(0xFFDBEAFE);
    }
  }

  Color get _fg {
    switch (status) {
      case SlotStatus.available:
        return Colors.grey.shade600;
      case SlotStatus.pendingCaregiver:
        return const Color(0xFFB45309);
      case SlotStatus.pendingDoctor:
        return AppColors.indigo;
      case SlotStatus.pendingCancellation:
        return const Color(0xFFC2410C);
      case SlotStatus.confirmed:
        return const Color(0xFF15803D);
      case SlotStatus.cancelled:
        return const Color(0xFFB91C1C);
      case SlotStatus.completed:
        return const Color(0xFF1D4ED8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        slotStatusLabel[status] ?? '',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NotificationBell — badge-wearing bell icon for app bars
// ─────────────────────────────────────────────
class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const NotificationBell(
      {super.key, required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NotificationsPanel — slide-in sheet
// ─────────────────────────────────────────────
class NotificationsPanel extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback onClose;

  const NotificationsPanel(
      {super.key, required this.notifications, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none, text: 'No notifications')
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade50),
                      itemBuilder: (_, i) {
                        final n =
                            notifications[notifications.length - 1 - i];
                        return Container(
                          color: n.read
                              ? null
                              : AppColors.indigo.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.text,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(n.time,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PriorityBadge
// ─────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  final Priority priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _bg => priority == Priority.high
      ? const Color(0xFFFEE2E2)
      : priority == Priority.medium
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFD1FAE5);

  Color get _fg => priority == Priority.high
      ? const Color(0xFFB91C1C)
      : priority == Priority.medium
          ? const Color(0xFFB45309)
          : const Color(0xFF065F46);

  String get _label => priority.name[0].toUpperCase() + priority.name.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text(_label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: _fg)),
    );
  }
}

// ─────────────────────────────────────────────
// MessageInput — shared send bar for all chat threads
// ─────────────────────────────────────────────
class MessageInput extends StatefulWidget {
  final String placeholder;
  final Color accentColor;
  final void Function(String text) onSend;

  const MessageInput({
    super.key,
    required this.placeholder,
    required this.accentColor,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _ctrl = TextEditingController();

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ChatBubble — used in all messaging screens
// ─────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isSelf;
  final Color selfColor;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isSelf,
    required this.selfColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelf ? selfColor : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSelf ? 16 : 4),
            bottomRight: Radius.circular(isSelf ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isSelf ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isSelf
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AuditLogSheet — bottom sheet showing slot history
// ─────────────────────────────────────────────
class AuditLogSheet extends StatelessWidget {
  final List<AuditLogEntry> log;
  const AuditLogSheet({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Audit Log',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: log.isEmpty
                ? const Center(
                    child: Text('No log entries yet.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: log.length,
                    itemBuilder: (_, i) {
                      final e = log[log.length - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.indigo,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(e.action,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${e.by} · ${e.role} · ${e.at}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                  ),
                                  if (e.note != null)
                                    Text(e.note!,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.indigo,
                                            fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
