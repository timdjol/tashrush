import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/services/notification_service.dart';

class RecordingNotificationGateway implements NotificationGateway {
  bool permission = true;
  final scheduled = <int>[];
  final cancelled = <int>[];

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> cancel(int id) async => cancelled.add(id);
  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async =>
      scheduled.add(id);
}

void main() {
  test('enabling notifications schedules daily and streak reminders', () async {
    final gateway = RecordingNotificationGateway();
    final service = NotificationService(gateway);

    expect(await service.setEnabled(true, 'ru'), isTrue);
    expect(gateway.scheduled, [1001, 1002]);
    expect(NotificationCopy.forLocale('ru').dailyTitle, 'Ежедневное испытание');
  });

  test('denied permission leaves reminders unscheduled', () async {
    final gateway = RecordingNotificationGateway()..permission = false;
    final service = NotificationService(gateway);

    expect(await service.setEnabled(true, 'en'), isFalse);
    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelled, [1001, 1002]);
  });
}
