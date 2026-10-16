import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late MemoryCloud cloud;
  late Device device;

  setUp(() async {
    cloud = MemoryCloud();
    device = await Device.create(cloud);
  });

  tearDown(() async {
    await device.close();
  });

  test(
    'a setlist recreated during cloud metadata check is not deleted',
    () async {
      await device.saveSetlist('recreated-setlist', 'Rehearsal', const []);
      await device.sync.sync();
      expect(cloud.has('setlist-recreated-setlist.json'), isTrue);

      await device.repo.deleteSetlist('recreated-setlist');
      var recreated = false;
      cloud.hook = (operation, _) async {
        if (operation == 'get' && !recreated) {
          recreated = true;
          await device.saveSetlist('recreated-setlist', 'Rehearsal', const []);
        }
      };

      final report = await device.sync.sync();
      cloud.hook = null;

      expect(recreated, isTrue);
      expect(report.deletedRemote, 0);
      expect(report.pending, 1);
      expect(cloud.has('setlist-recreated-setlist.json'), isTrue);
      expect(
        (await device.repo.getSetlist('recreated-setlist'))?.name,
        'Rehearsal',
      );
      expect(
        await device.repo.database.query(
          'outbox',
          where: 'object_id = ? AND object_kind = ? AND action = ?',
          whereArgs: ['recreated-setlist', 'setlist', 'save'],
        ),
        isNotEmpty,
      );
    },
  );
}
