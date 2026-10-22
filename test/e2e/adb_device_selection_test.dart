import 'package:flutter_test/flutter_test.dart';
import '../../test_driver/support/adb_device_selection.dart';

void main() {
  test('selects the only ready device from CRLF listing with extra columns', () {
    expect(
      selectAdbDeviceSerial(
        stdout:
            'List of devices attached\r\nemulator-5554\tdevice product:a model:b transport_id:1\r\n',
        exitCode: 0,
      ),
      'emulator-5554',
    );
  });

  test('selects an explicit ready serial among multiple devices', () {
    expect(
      selectAdbDeviceSerial(
        stdout: 'List of devices attached\nfirst\tdevice\nsecond\tdevice\n',
        exitCode: 0,
        configuredSerial: ' second ',
      ),
      'second',
    );
  });

  test('refuses multiple ready devices without an explicit serial', () {
    expect(
      () => selectAdbDeviceSerial(
        stdout: 'List of devices attached\nfirst\tdevice\nsecond\tdevice\n',
        exitCode: 0,
      ),
      throwsStateError,
    );
  });

  test('ignores offline and unauthorized devices', () {
    expect(
      selectAdbDeviceSerial(
        stdout:
            'List of devices attached\noffline-1\toffline\nauth-1\tunauthorized\nready-1\tdevice\n',
        exitCode: 0,
      ),
      'ready-1',
    );
  });

  test('requires the exact ready device status token', () {
    for (final status in ['devices', 'devicefoo', 'device\u0008']) {
      expect(
        () => selectAdbDeviceSerial(
          stdout: 'List of devices attached\nserial\t$status\n',
          exitCode: 0,
        ),
        throwsStateError,
        reason: 'Status token "$status" must not be treated as ready.',
      );
    }
  });

  test(
    'refuses an empty or non-ready listing instead of guessing a device',
    () {
      for (final stdout in [
        'List of devices attached\n',
        'List of devices attached\noffline-1\toffline\nauth-1\tunauthorized\n',
      ]) {
        expect(
          () => selectAdbDeviceSerial(stdout: stdout, exitCode: 0),
          throwsStateError,
        );
      }
    },
  );

  test('refuses a configured serial unless that exact device is ready', () {
    const listing =
        'List of devices attached\nother\tdevice\nrequested\toffline\n';
    expect(
      () => selectAdbDeviceSerial(
        stdout: listing,
        exitCode: 0,
        configuredSerial: 'requested',
      ),
      throwsStateError,
    );
    expect(
      () => selectAdbDeviceSerial(
        stdout: listing,
        exitCode: 0,
        configuredSerial: 'missing',
      ),
      throwsStateError,
    );
  });

  test('refuses a failed listing even when a serial is configured', () {
    expect(
      () => selectAdbDeviceSerial(
        stdout: 'requested\tdevice\n',
        exitCode: 1,
        configuredSerial: 'requested',
      ),
      throwsStateError,
    );
  });

  test('blank configured serial uses unique-device selection', () {
    expect(
      selectAdbDeviceSerial(
        stdout: 'List of devices attached\nonly\tdevice\n',
        exitCode: 0,
        configuredSerial: '  ',
      ),
      'only',
    );
  });

  test('accepts standard device status before extended columns', () {
    expect(
      selectAdbDeviceSerial(
        stdout: 'List of devices attached\nserial\tdevice product:model\n',
        exitCode: 0,
      ),
      'serial',
    );
  });
}
