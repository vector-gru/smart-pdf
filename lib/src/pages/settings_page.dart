import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../settings/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  final SettingsProvider settingsProvider;
  const SettingsPage({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawerSettings)),
      body: ListenableBuilder(
        listenable: settingsProvider,
        builder: (context, _) => ListView(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsAutoCrop),
              subtitle: Text(l10n.settingsAutoCropSubtitle),
              value: settingsProvider.autoCrop,
              onChanged: settingsProvider.setAutoCrop,
            ),
          ],
        ),
      ),
    );
  }
}
