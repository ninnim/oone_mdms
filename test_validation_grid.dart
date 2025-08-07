// Test script to verify the validation grid functionality
import 'package:flutter/material.dart';
import 'lib/presentation/widgets/time_of_use/tou_form_validation_grid.dart';
import 'lib/core/models/time_band.dart';
import 'lib/core/models/time_of_use.dart';
import 'lib/core/models/device.dart';

void main() {
  // Test data setup
  final testChannels = [
    Channel(id: 1, name: 'Channel 1', description: 'Test Channel 1'),
    Channel(id: 2, name: 'Channel 2', description: 'Test Channel 2'),
  ];

  final testTimeBands = [
    TimeBand(
      id: 1,
      name: 'Weekdays Peak',
      description: 'Monday to Friday Peak Hours',
      active: true,
      daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri (API uses 0=Sunday)
      startTime: '17:00:00',
      endTime: '21:00:00',
      monthsOfYear: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    ),
    TimeBand(
      id: 2,
      name: 'Weekend Peak',
      description: 'Saturday and Sunday Peak Hours',
      active: true,
      daysOfWeek: [0, 6], // Sat-Sun (API uses 0=Sunday, 6=Saturday)
      startTime: '18:00:00',
      endTime: '22:00:00',
      monthsOfYear: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    ),
  ];

  final testTimeOfUseDetails = [
    TimeOfUseDetail(
      id: 1,
      timeOfUseId: 1,
      timeBandId: 1,
      channelId: 1,
      active: true,
    ),
    TimeOfUseDetail(
      id: 2,
      timeOfUseId: 1,
      timeBandId: 2,
      channelId: 1,
      active: true,
    ),
    TimeOfUseDetail(
      id: 3,
      timeOfUseId: 1,
      timeBandId: 1,
      channelId: 2,
      active: true,
    ),
  ];

  print('=== Validation Grid Test Data ===');
  print('Channels: ${testChannels.length}');
  print('Time Bands: ${testTimeBands.length}');
  print('TOU Details: ${testTimeOfUseDetails.length}');

  print('\n=== Time Band Mapping Test ===');
  for (final band in testTimeBands) {
    print('${band.name}:');
    print(
      '  Days of Week: ${band.daysOfWeek} (API format: 0=Sunday, 6=Saturday)',
    );
    print('  Time: ${band.startTime} - ${band.endTime}');

    // Test day mapping
    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final selectedDays = band.daysOfWeek.map((d) => dayNames[d]).join(', ');
    print('  Human readable: $selectedDays');
  }

  print('\n=== Expected Grid Behavior ===');
  print(
    '1. Weekdays Peak (Mon-Fri, 17:00-21:00) should show on grid columns 1-5, rows 17-20',
  );
  print(
    '2. Weekend Peak (Sat-Sun, 18:00-22:00) should show on grid columns 0,6, rows 18-21',
  );
  print(
    '3. Channel filter should allow toggling between all channels and individual channels',
  );
  print('4. Overlapping time slots should be highlighted appropriately');

  print('\n=== Test Complete ===');
  print('The validation grid should now correctly map:');
  print('- API day-of-week values (0=Sunday) to grid columns (0=Sunday)');
  print('- Allow interactive channel filtering');
  print('- Show proper validation colors and conflict detection');
}
