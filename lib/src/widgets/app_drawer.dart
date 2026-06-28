import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../pages/open_source_licenses_page.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onImportFiles;
  final VoidCallback? onImportImages;

  const AppDrawer({super.key, this.onImportFiles, this.onImportImages});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset('assets/logo/smartPDF.png', width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  const Text('SmartPDF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _Item(icon: Icons.drive_folder_upload_outlined, label: 'Import files', onTap: () { Navigator.pop(context); onImportFiles?.call(); }),
                  _Item(icon: Icons.image_outlined, label: 'Import Images', onTap: () { Navigator.pop(context); onImportImages?.call(); }),
                  _Item(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.brightness_4_outlined, label: 'Theme', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.thumb_up_outlined, label: 'Rate app', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.language_outlined, label: 'Language', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.share_outlined, label: 'Share this app', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.feedback_outlined, label: 'Send feedback', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.privacy_tip_outlined, label: 'Privacy policy', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.source_outlined, label: 'Open Source Licenses', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSourceLicensesPage()));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Item({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconAction),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
      dense: false,
    );
  }
}
