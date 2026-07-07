import 'package:flutter/material.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/screens/patient/patient_tab.dart';

/// Page header used throughout the patient dashboard, styled larger and
/// simpler than the doctor/caregiver headers for dementia-friendly use.
class PatientPageHeader extends StatelessWidget {
  final String title;
  final String breadcrumb;
  final VoidCallback onBack;
  final VoidCallback onHome;

  const PatientPageHeader({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.patientBg,
          border: Border(bottom: BorderSide(color: AppColors.patientBorder)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.patientText),
                  label: const Text('Back',
                      style: TextStyle(
                          color: AppColors.patientText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.patientText)),
                ),
                TextButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home, color: AppColors.patientText),
                  label: const Text('Home',
                      style: TextStyle(
                          color: AppColors.patientText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(breadcrumb,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.patientSubtext)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientBottomNav extends StatelessWidget {
  final PatientTab active;
  final ValueChanged<PatientTab> onSelect;

  const PatientBottomNav({super.key, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (PatientTab.home, 'Home', Icons.home),
      (PatientTab.medicines, 'Medicines', Icons.medication),
      (PatientTab.appointments, 'Appointments', Icons.calendar_month),
      (PatientTab.chatbot, 'Help', Icons.chat_bubble_outline),
      (PatientTab.messages, 'Messages', Icons.message),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppColors.patientBorder, width: 2)),
      ),
      child: Row(
        children: tabs.map((t) {
          final selected = active == t.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(t.$1),
              child: Container(
                color: selected ? const Color(0xFFFFF8F0) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        color: selected
                            ? const Color(0xFFD97706)
                            : AppColors.patientSubtext),
                    const SizedBox(height: 2),
                    Text(t.$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                            color: selected
                                ? AppColors.patientText
                                : AppColors.patientSubtext)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SOSButton extends StatelessWidget {
  final VoidCallback onTrigger;
  const SOSButton({super.key, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      child: InkWell(
        onTap: onTrigger,
        child: Container(
          width: double.infinity,
          height: 72,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text('SOS — Get Help Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}
