import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final settings = services.settings.value;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(
            title: Text(l10n.sound),
            secondary: const Icon(Icons.volume_up_rounded),
            value: settings.sound,
            onChanged: (value) =>
                services.settings.update(settings.copyWith(sound: value))),
        SwitchListTile(
            title: Text(l10n.music),
            secondary: const Icon(Icons.music_note_rounded),
            value: settings.music,
            onChanged: (value) =>
                services.settings.update(settings.copyWith(music: value))),
        SwitchListTile(
            title: Text(l10n.vibration),
            secondary: const Icon(Icons.vibration_rounded),
            value: settings.vibration,
            onChanged: (value) =>
                services.settings.update(settings.copyWith(vibration: value))),
        SwitchListTile(
            title: Text(l10n.notifications),
            secondary: const Icon(Icons.notifications_rounded),
            value: settings.notifications,
            onChanged: (value) => services.settings
                .update(settings.copyWith(notifications: value))),
        ListTile(
          leading: const Icon(Icons.language_rounded),
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: settings.locale.languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
              DropdownMenuItem(value: 'ky', child: Text('Кыргызча')),
            ],
            onChanged: (value) {
              if (value != null) {
                services.settings
                    .update(settings.copyWith(locale: Locale(value)));
              }
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.block_rounded),
          title: Text(l10n.removeAds),
          subtitle: Text(l10n.comingSoon),
          onTap: () => Navigator.pushNamed(context, AppRoutes.removeAds),
        ),
      ]),
    );
  }
}
