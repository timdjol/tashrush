import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/services/progression_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('journey themes unlock from total cleared lines', () async {
    SharedPreferences.setMockInitialValues({'totalLines': 99});
    final storage = await StorageService.create();
    final service = ProgressionService(storage);
    final issykKul = ProgressionService.themes[1];

    expect(service.isUnlocked(issykKul), isFalse);
    expect(await service.select(issykKul), isFalse);

    await storage.setInt('totalLines', 100);
    expect(service.isUnlocked(issykKul), isTrue);
    expect(await service.select(issykKul), isTrue);
    expect(service.selected.theme, JourneyTheme.issykKul);
  });
}
