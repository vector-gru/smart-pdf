import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../pages/open_source_licenses_page.dart';
import '../pages/privacy_policy_page.dart';
import 'feedback_sheet.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) => setState(() => _version = 'v${i.version}'));
  }

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
                  _Item(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.brightness_4_outlined, label: 'Theme', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.thumb_up_outlined, label: 'Rate app', onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(AppConstants.playStoreUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }),
                  _Item(icon: Icons.language_outlined, label: 'Language', onTap: () => Navigator.pop(context)),
                  _Item(icon: Icons.share_outlined, label: 'Share this app', onTap: () {
                    Navigator.pop(context);
                    Share.share(AppConstants.shareAppMessage);
                  }),
                  _Item(icon: Icons.feedback_outlined, label: 'Feedback & Social', onTap: () {
                    Navigator.pop(context);
                    showFeedbackSheet(context);
                  }),
                  _Item(icon: Icons.privacy_tip_outlined, label: 'Privacy policy', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                  }),
                  _Item(icon: Icons.source_outlined, label: 'Open Source Licenses', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSourceLicensesPage()));
                  }),
                ],
              ),
            ),
            if (_version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Center(
                  child: Text(
                    _version,
                    style: const TextStyle(
                      fontSize: AppConstants.fontSubtitle,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
