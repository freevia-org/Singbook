// Original lyric fixtures cover the reported Moon Over Bourbon Street chord
// vocabulary without assuming its first chord is the song's key.
const transposePopupFixtures = [
  (
    name: 'Altered minor movement',
    key: null,
    pitch: null,
    body:
        '[Gm7b5]Harbor [C7]lights\n[Fm]Quiet [Fm/C]water [Fm/E]turns\n'
        '[Fm/Eb]Beneath [Fm/D]the [Db]sky [C7]tonight',
    shifted: ['Am7b5', 'D7', 'Gm', 'Gm/D', 'Gm/F#', 'Gm/F', 'Gm/E', 'Eb', 'D7'],
    shiftedKey: null,
    down: ['F#m7b5', 'B7', 'Em', 'Em/B', 'Em/D#', 'Em/D', 'Em/C#', 'C', 'B7'],
  ),
  (
    name: 'Invalid key with major progression',
    key: 'H',
    pitch: null,
    body: '[C]Morning [G/B]road\n[Am7]Homeward [Fmaj7]again',
    shifted: ['D', 'A/C#', 'Bm7', 'Gmaj7'],
    shiftedKey: 'H',
    down: ['B', 'F#/A#', 'G#m7', 'Emaj7'],
  ),
  (
    name: 'Minor guitar arrangement',
    key: 'Em',
    pitch: 4,
    body: '[Em]Lantern [C]glow\n[G]Across [D/F#]the hills',
    shifted: ['F#m', 'D', 'A', 'E/G#'],
    shiftedKey: 'F#m',
    down: ['D#m', 'B', 'F#', 'C#/F'],
  ),
  (
    name: 'Flat minor arrangement',
    key: 'Fm',
    pitch: 5,
    body: '[Fm]Silent [Bbm7]shore\n[Dbmaj7]Open [C7/E]door',
    shifted: ['Gm', 'Cm7', 'Ebmaj7', 'D7/F#'],
    shiftedKey: 'Gm',
    down: ['Em', 'Am7', 'Cmaj7', 'B7/D#'],
  ),
  (
    name: 'Sharp key and enharmonic bass',
    key: 'F#',
    pitch: 6,
    body: '[F#]Northern [C#/E#]wind\n[B]Brings [D#m7]us home',
    shifted: ['G#', 'D#/G', 'C#', 'Fm7'],
    shiftedKey: 'G#',
    down: ['F', 'C/E', 'A#', 'Dm7'],
  ),
  (
    name: 'Keyless instrumental chords',
    key: '',
    pitch: null,
    body: '[Bbmaj7] [F/A] [Gm7] [Cm9]',
    shifted: ['Cmaj7', 'G/B', 'Am7', 'Dm9'],
    shiftedKey: null,
    down: ['Amaj7', 'E/G#', 'F#m7', 'Bm9'],
  ),
];
