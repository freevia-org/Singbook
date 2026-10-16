import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/home/source_version_widgets.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  test('best available stays first even when it uses one provider', () {
    const combined = SourceVersionData(
      id: 'combined',
      providerId: 'combined',
      providerName: 'Songsterr',
      title: 'Example',
      artist: 'Artist',
      sourceCount: 1,
      underlyingSourceId: 'songsterr:example',
    );
    const source = SourceVersionData(
      id: 'songsterr:example',
      providerId: 'songsterr',
      providerName: 'Songsterr',
      title: 'Example',
      artist: 'Artist',
    );
    const comparison = SearchComparisonData(
      reference: SearchReferenceData(
        id: 'catalog:example',
        title: 'Example',
        artist: 'Artist',
      ),
      suggested: combined,
      alternatives: [source],
      selectedVersionId: 'combined',
    );

    final versions = comparisonVersions(comparison);

    expect(versions.map((version) => version.id), [
      'combined',
      'songsterr:example',
    ]);
    expect(versionSelectionId(versions.first), 'combined');
  });
}
