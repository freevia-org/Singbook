import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/singbook_journey_device_test.dart' as journey;

void main() {
  test('journey fixture provides the expected discovery states', () async {
    final actual = await journey.runSingbookFixturePreflight();

    expect(actual['quietFirstUsable'], 0);
    expect(actual['quietFirstUnavailableCount'], 6);
    expect(actual['quietFirstTimingOnlyTracks'], 0);
    expect(actual['quietRetryUsable'], 3);
    expect(actual['mainUsable'], 3);
    expect(actual['mainUnavailableCount'], 2);
    expect(actual['mainContributors'], 2);
    expect(actual['mainTimingOnlyState'], 'found');
    expect(actual['mainUnavailableState'], 'unavailable');
    expect(actual['mainFailureState'], 'failed');
  });
}
