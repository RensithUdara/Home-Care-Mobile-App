import 'package:flutter/material.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/themes/app_colors.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final String contactNote;

  const LegalPage({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.contactNote,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ModernAppBar(
        title: title,
        subtitle: 'Last updated: August 2024',
        showBack: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 92, 20, 40),
        children: [
          Entrance(
            child: DepthCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconOrb(icon: icon, color: AppColors.primary, size: 52),
                  const SizedBox(height: 16),
                  SelectableText(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(contactNote,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
