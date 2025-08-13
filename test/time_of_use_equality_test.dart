import 'package:flutter_test/flutter_test.dart';
import 'package:mdms_clone/core/models/time_of_use.dart';

void main() {
  group('TimeOfUse Equality Tests', () {
    test('TimeOfUse objects with same id should be equal', () {
      final timeOfUse1 = TimeOfUse(
        id: 1,
        code: 'TOU01',
        name: 'Test TOU',
        description: 'Test Description',
        active: true,
        timeOfUseDetails: [],
      );

      final timeOfUse2 = TimeOfUse(
        id: 1,
        code: 'TOU02', // Different code but same id
        name: 'Different Name',
        description: 'Different Description',
        active: false,
        timeOfUseDetails: [],
      );

      expect(timeOfUse1, equals(timeOfUse2));
      expect(timeOfUse1.hashCode, equals(timeOfUse2.hashCode));
    });

    test('TimeOfUse objects with different id should not be equal', () {
      final timeOfUse1 = TimeOfUse(
        id: 1,
        code: 'TOU01',
        name: 'Test TOU',
        description: 'Test Description',
        active: true,
        timeOfUseDetails: [],
      );

      final timeOfUse2 = TimeOfUse(
        id: 2, // Different id
        code: 'TOU01', // Same code but different id
        name: 'Test TOU',
        description: 'Test Description',
        active: true,
        timeOfUseDetails: [],
      );

      expect(timeOfUse1, isNot(equals(timeOfUse2)));
    });

    test('Set contains check should work correctly', () {
      final timeOfUse1 = TimeOfUse(
        id: 1,
        code: 'TOU01',
        name: 'Test TOU',
        description: 'Test Description',
        active: true,
        timeOfUseDetails: [],
      );

      final timeOfUse2 = TimeOfUse(
        id: 1,
        code: 'TOU02', // Different code but same id
        name: 'Different Name',
        description: 'Different Description',
        active: false,
        timeOfUseDetails: [],
      );

      final selectedItems = <TimeOfUse>{timeOfUse1};

      // This should return true because timeOfUse2 has the same id as timeOfUse1
      expect(selectedItems.contains(timeOfUse2), isTrue);
    });

    test('TimeOfUseDetail equality should work', () {
      final detail1 = TimeOfUseDetail(
        id: 1,
        timeBandId: 100,
        channelId: 200,
        registerDisplayCode: 'RDC01',
        priorityOrder: 1,
        active: true,
      );

      final detail2 = TimeOfUseDetail(
        id: 1,
        timeBandId: 101, // Different timeBandId but same id
        channelId: 201,
        registerDisplayCode: 'RDC02',
        priorityOrder: 2,
        active: false,
      );

      expect(detail1, equals(detail2));
      expect(detail1.hashCode, equals(detail2.hashCode));
    });

    test('Channel equality should work', () {
      final channel1 = Channel(
        id: 1,
        code: 'CH01',
        name: 'Channel 1',
        units: 'V',
        flowDirection: 'Import',
        phase: 'A',
        apportionPolicy: 'AVG',
        active: true,
      );

      final channel2 = Channel(
        id: 1,
        code: 'CH02', // Different code but same id
        name: 'Channel 2',
        units: 'A',
        flowDirection: 'Export',
        phase: 'B',
        apportionPolicy: 'SUM',
        active: false,
      );

      expect(channel1, equals(channel2));
      expect(channel1.hashCode, equals(channel2.hashCode));
    });
  });
}
