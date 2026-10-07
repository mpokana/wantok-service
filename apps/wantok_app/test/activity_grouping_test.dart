import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';

void main() {
  final now = DateTime(2026, 10, 7, 13);

  test('groups active requests and in-progress work as ongoing', () {
    expect(
      trackActivityGroupForBooking(<String, dynamic>{
        'status': 'requested',
      }, now: now),
      TrackActivityGroup.ongoing,
    );

    expect(
      trackActivityGroupForBooking(<String, dynamic>{
        'status': 'in_progress',
        'scheduled_start': DateTime(2026, 10, 8, 9).toIso8601String(),
      }, now: now),
      TrackActivityGroup.ongoing,
    );
  });

  test('groups future non-terminal bookings as scheduled', () {
    for (final status in <String>[
      'requested',
      'quoted',
      'accepted',
      'confirmed',
    ]) {
      expect(
        trackActivityGroupForBooking(<String, dynamic>{
          'status': status,
          'scheduled_start': DateTime(2026, 10, 8, 9).toIso8601String(),
        }, now: now),
        TrackActivityGroup.scheduled,
        reason: status,
      );
    }
  });

  test('keeps already-due non-terminal bookings in ongoing', () {
    expect(
      trackActivityGroupForBooking(<String, dynamic>{
        'status': 'confirmed',
        'scheduled_start': DateTime(2026, 10, 7, 9).toIso8601String(),
      }, now: now),
      TrackActivityGroup.ongoing,
    );
  });

  test('groups all terminal booking states under completed history', () {
    for (final status in <String>[
      'completed',
      'cancelled',
      'rejected',
      'expired',
    ]) {
      expect(
        trackActivityGroupForBooking(<String, dynamic>{
          'status': status,
          'scheduled_start': DateTime(2026, 10, 8, 9).toIso8601String(),
        }, now: now),
        TrackActivityGroup.completed,
        reason: status,
      );
    }
  });
}
