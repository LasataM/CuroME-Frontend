import 'package:flutter/material.dart';
import 'package:curome/constants/constants.dart';
import 'package:curome/models/models.dart';
import 'package:curome/screens/patient/patient_widgets.dart';

class PatientChatbotTab extends StatefulWidget {
  final VoidCallback onHome;

  const PatientChatbotTab({super.key, required this.onHome});

  @override
  State<PatientChatbotTab> createState() => _PatientChatbotTabState();
}

class _PatientChatbotTabState extends State<PatientChatbotTab> {
  String _chatNodeId = 'root';

  IconData _chatIcon(String label) {
    switch (label) {
      case 'My medicine':
        return Icons.medication;
      case 'I feel upset':
        return Icons.favorite;
      case 'Call my caregiver':
        return Icons.phone;
      case 'Return Home':
      case 'Home':
        return Icons.home;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = chatTree[_chatNodeId] ?? chatTree['root']!;
    return Column(
      children: [
        PatientPageHeader(
          title: 'Get Help',
          breadcrumb: 'Home > Help',
          onBack: widget.onHome,
          onHome: widget.onHome,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.patientBorder),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(node.text,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.patientText,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final opt in node.options.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      onTap: () => setState(() => _chatNodeId = opt.next),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 68),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFD97706), width: 2),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(_chatIcon(opt.label),
                                color: const Color(0xFFD97706)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(opt.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.patientText)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.settings, size: 18, color: Color(0xFF92400E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('This helper works without internet',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF92400E))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
