import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:battery_guardian/core/constants/app_constants.dart';
import 'package:battery_guardian/core/utils/battery_status_helper.dart';
import 'package:battery_guardian/core/utils/battery_health_score.dart';
import 'package:battery_guardian/features/battery/models/battery_info.dart';

void main() {
  group('AppConstants', () {
    test('default values are within valid ranges', () {
      expect(AppConstants.defaultAlertLevel, inInclusiveRange(50, 100));
      expect(AppConstants.defaultLowBatteryLevel, inInclusiveRange(5, 50));
      expect(AppConstants.defaultQuietHoursStart, inInclusiveRange(0, 23));
      expect(AppConstants.defaultQuietHoursEnd, inInclusiveRange(0, 23));
      expect(AppConstants.defaultTempThreshold, inInclusiveRange(30, 60));
    });
  });

  group('BatteryStatusHelper', () {
    test('isCharging returns true for charging and full', () {
      expect(BatteryStatusHelper.isCharging(BatteryState.charging), isTrue);
      expect(BatteryStatusHelper.isCharging(BatteryState.full), isTrue);
      expect(BatteryStatusHelper.isCharging(BatteryState.discharging), isFalse);
      expect(BatteryStatusHelper.isCharging(BatteryState.unknown), isFalse);
    });

    test('isPluggedIn returns true when connected', () {
      expect(BatteryStatusHelper.isPluggedIn(BatteryState.charging), isTrue);
      expect(BatteryStatusHelper.isPluggedIn(BatteryState.full), isTrue);
      expect(
        BatteryStatusHelper.isPluggedIn(BatteryState.connectedNotCharging),
        isTrue,
      );
      expect(BatteryStatusHelper.isPluggedIn(BatteryState.discharging), isFalse);
    });
  });

  group('BatteryInfo', () {
    test('initial values are unknown', () {
      final info = BatteryInfo.initial();
      expect(info.level, 0);
      expect(info.state, BatteryState.unknown);
      expect(info.temperature, isNull);
      expect(info.voltage, isNull);
    });

    test('copyWith preserves unset fields', () {
      final info = BatteryInfo(
        level: 50,
        state: BatteryState.charging,
        temperature: 28.5,
      );
      final copy = info.copyWith(level: 75);
      expect(copy.level, 75);
      expect(copy.state, BatteryState.charging);
      expect(copy.temperature, 28.5);
    });

    test('hasUiChangedFrom detects level change', () {
      final a = BatteryInfo(level: 50, state: BatteryState.charging);
      final b = BatteryInfo(level: 51, state: BatteryState.charging);
      expect(a.hasUiChangedFrom(b), isTrue);
    });

    test('hasAlertRelevantChangeFrom detects state changes', () {
      final a = BatteryInfo(level: 80, state: BatteryState.charging);
      final b = BatteryInfo(level: 80, state: BatteryState.full);
      expect(a.hasAlertRelevantChangeFrom(b), isTrue);
    });

    test('same level and state does not trigger change', () {
      final a = BatteryInfo(level: 75, state: BatteryState.charging);
      final b = BatteryInfo(level: 75, state: BatteryState.charging);
      expect(a.hasAlertRelevantChangeFrom(b), isFalse);
      expect(a.hasUiChangedFrom(b), isFalse);
    });
  });

  group('QuietHoursHelper', () {
    test('isActive returns false when disabled', () {
      expect(
        QuietHoursHelper.isActive(
          enabled: false,
          startHour: 22,
          endHour: 8,
        ),
        isFalse,
      );
    });

    test('isActive returns false when start equals end', () {
      expect(
        QuietHoursHelper.isActive(
          enabled: true,
          startHour: 8,
          endHour: 8,
        ),
        isFalse,
      );
    });
  });
}
