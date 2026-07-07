import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curome/state/app_state.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/widgets/common_widgets.dart';

class CaregiverRemindersTab extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const CaregiverRemindersTab({super.key, required this.onBack});

  @override
  ConsumerState<CaregiverRemindersTab> createState() =>
      _CaregiverRemindersTabState();
}

class _CaregiverRemindersTabState
    extends ConsumerState<CaregiverRemindersTab> {
  bool _showAddReminder = false;
  final _reminderLabelCtrl = TextEditingController();
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;

  @override
  void dispose() {
    _reminderLabelCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) => t.format(context);

  DateTime _combineDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final medicationReminders = state.medicationReminders;
    return Column(
      children: [
        PageHeader(
          title: 'Medicine',
          onBack: widget.onBack,
          action: IconButton(
            icon: Icon(_showAddReminder ? Icons.close : Icons.add,
                color: AppColors.indigo),
            onPressed: () =>
                setState(() => _showAddReminder = !_showAddReminder),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showAddReminder)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Medicine Reminder',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.indigo)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reminderLabelCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Medicine name',
                            filled: true,
                            fillColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _reminderDate = picked);
                                }
                              },
                              child: Text(_reminderDate == null
                                  ? 'Select date'
                                  : _fmtDate(_reminderDate!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now());
                                if (picked != null) {
                                  setState(() => _reminderTime = picked);
                                }
                              },
                              child: Text(_reminderTime == null
                                  ? 'Select time'
                                  : _fmtTime(_reminderTime!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                  'Patient and caregiver will be notified 5 minutes before the dose.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_reminderLabelCtrl.text.trim().isEmpty ||
                                _reminderDate == null ||
                                _reminderTime == null) {
                              return;
                            }
                            final dateStr = _fmtDate(_reminderDate!);
                            final timeStr = _fmtTime(_reminderTime!);
                            state.addMedicationReminder(
                              label: _reminderLabelCtrl.text.trim(),
                              date: dateStr,
                              time: timeStr,
                              dueAt: _combineDateTime(
                                  _reminderDate!, _reminderTime!),
                            );
                            _reminderLabelCtrl.clear();
                            setState(() {
                              _reminderDate = null;
                              _reminderTime = null;
                              _showAddReminder = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo),
                          child: const Text('Save Medicine Reminder',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              _sectionLabel('Medication Reminders', AppColors.indigo),
              if (medicationReminders.isEmpty)
                const EmptyState(
                    icon: Icons.medication, text: 'No medicines scheduled yet.')
              else
                for (final r in medicationReminders) _medicineReminderCard(r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1)),
      );

  Widget _medicineReminderCard(Reminder r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.medication, color: AppColors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${r.date.isEmpty ? "Today" : r.date} at ${r.time}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Reminder goes out 5 minutes before',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Pending',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade800)),
          ),
        ],
      ),
    );
  }
}
