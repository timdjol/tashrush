import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../localization/app_localizations.dart';
import '../../services/progression_service.dart';
import '../../widgets/rush_card.dart';

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
        _VolumeSlider(
          title: l10n.soundVolume,
          icon: Icons.graphic_eq_rounded,
          enabled: settings.sound,
          value: settings.soundVolume,
          onChanged: (value) =>
              services.settings.update(settings.copyWith(soundVolume: value)),
        ),
        SwitchListTile(
            title: Text(l10n.music),
            secondary: const Icon(Icons.music_note_rounded),
            value: settings.music,
            onChanged: (value) =>
                services.settings.update(settings.copyWith(music: value))),
        _VolumeSlider(
          title: l10n.musicVolume,
          icon: Icons.equalizer_rounded,
          enabled: settings.music,
          value: settings.musicVolume,
          onChanged: (value) =>
              services.settings.update(settings.copyWith(musicVolume: value)),
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.journeyThemes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final item in ProgressionService.themes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RushCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: ListTile(
                enabled: services.progression.isUnlocked(item),
                onTap: services.progression.isUnlocked(item)
                    ? () => services.progression.select(item)
                    : null,
                leading: CircleAvatar(backgroundColor: item.accent),
                title: Text(switch (item.theme) {
                  JourneyTheme.alaToo => l10n.themeAlaToo,
                  JourneyTheme.issykKul => l10n.themeIssykKul,
                  JourneyTheme.osh => l10n.themeOsh,
                }),
                subtitle: services.progression.isUnlocked(item)
                    ? Text(l10n.unlocked)
                    : Text('${l10n.clearLines}: ${item.requiredLines}'),
                trailing: Icon(
                  services.progression.selected.theme == item.theme
                      ? Icons.check_circle_rounded
                      : services.progression.isUnlocked(item)
                          ? Icons.circle_outlined
                          : Icons.lock_outline_rounded,
                  color: services.progression.selected.theme == item.theme
                      ? item.accent
                      : null,
                ),
              ),
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

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Row(children: [
          Expanded(child: Text(title)),
          Text('${(value * 100).round()}%'),
        ]),
        subtitle: Slider(
          value: value.clamp(0, 1),
          onChanged: enabled ? onChanged : null,
        ),
      );
}
