import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/locale_provider.dart';
import '../theme/theme_provider.dart';
import '../pages/open_source_licenses_page.dart';
import '../pages/privacy_policy_page.dart';
import 'feedback_sheet.dart';

class AppDrawer extends StatefulWidget {
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;
  const AppDrawer({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then(
      (i) => setState(() => _version = 'v${i.version}'),
    );
  }

  void _showThemePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.themeProvider.mode;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.themeSheetTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _ThemeTile(
              label: l10n.themeLight,
              mode: AppThemeMode.light,
              selected: current == AppThemeMode.light,
              onTap: () {
                widget.themeProvider.setMode(AppThemeMode.light);
                Navigator.pop(sheetContext);
              },
            ),
            _ThemeTile(
              label: l10n.themeDark,
              mode: AppThemeMode.dark,
              selected: current == AppThemeMode.dark,
              onTap: () {
                widget.themeProvider.setMode(AppThemeMode.dark);
                Navigator.pop(sheetContext);
              },
            ),
            _ThemeTile(
              label: l10n.themeDevice,
              mode: AppThemeMode.device,
              selected: current == AppThemeMode.device,
              onTap: () {
                widget.themeProvider.setMode(AppThemeMode.device);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeProvider.locale;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.languageSheetTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _LocaleTile(
              label: l10n.languageEnglish,
              locale: const Locale('en'),
              selected: current.languageCode == 'en',
              onTap: () {
                widget.localeProvider.setLocale(const Locale('en'));
                Navigator.pop(sheetContext);
              },
            ),
            _LocaleTile(
              label: l10n.languageFrench,
              locale: const Locale('fr'),
              selected: current.languageCode == 'fr',
              onTap: () {
                widget.localeProvider.setLocale(const Locale('fr'));
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    child: Image.asset(
                      'assets/logo/smartPDF.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'SmartPDF',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _Item(
                    icon: Icons.settings_outlined,
                    label: l10n.drawerSettings,
                    onTap: () => Navigator.pop(context),
                  ),
                  _Item(
                    icon: Icons.brightness_4_outlined,
                    label: l10n.drawerTheme,
                    onTap: () {
                      Navigator.pop(context);
                      _showThemePicker(context);
                    },
                  ),
                  _Item(
                    icon: Icons.thumb_up_outlined,
                    label: l10n.drawerRateApp,
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse(AppConstants.playStoreUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _Item(
                    icon: Icons.language_outlined,
                    label: l10n.drawerLanguage,
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguagePicker(context);
                    },
                  ),
                  _Item(
                    icon: Icons.share_outlined,
                    label: l10n.drawerShareApp,
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(AppConstants.shareAppMessage);
                    },
                  ),
                  _Item(
                    icon: Icons.feedback_outlined,
                    label: l10n.drawerFeedback,
                    onTap: () {
                      Navigator.pop(context);
                      showFeedbackSheet(context);
                    },
                  ),
                  _Item(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.drawerPrivacy,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _Item(
                    icon: Icons.source_outlined,
                    label: l10n.drawerLicenses,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OpenSourceLicensesPage(),
                        ),
                      );
                    },
                  ),
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

class _ThemeTile extends StatelessWidget {
  final String label;
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryMuted)
          : null,
      onTap: onTap,
    );
  }
}

class _LocaleTile extends StatelessWidget {
  final String label;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  const _LocaleTile({
    required this.label,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryMuted)
          : null,
      onTap: onTap,
    );
  }
}
