# Appearance fonts

These fonts are bundled so the appearance options and their previews work
offline. Each family includes regular (400) and bold (700) faces and covers
Latin, Bulgarian, and Ukrainian characters. Other scripts retain Flutter's
platform font fallback. Italic styles use the platform's synthesized face.
The original licenses are bundled alongside the fonts and registered in the
app's license list.

## Lora

Unmodified static TrueType files from the official Cyreal repository:

- Repository: https://github.com/cyrealtype/Lora-Cyrillic
- Commit: `2d53b449b60e185b39f671b44fded83e0910ad30`
- Files: `fonts/ttf/Lora-Regular.ttf`, `fonts/ttf/Lora-Bold.ttf`
- License: upstream `OFL.txt`, bundled as `Lora-OFL.txt`

## Nunito

Static regular and bold instances of the official variable font:

- Repository: https://github.com/googlefonts/nunito
- Commit: `8c6a9bb9732545b9ed53f29ec5e1ab0ff53c4e6f`
- Source: `fonts/variable/Nunito[wght].ttf`
- License: upstream `OFL.txt`, bundled as `Nunito-OFL.txt`

The only transformation is pinning the weight axis and updating instance names
with fontTools 4.65.0. Reproduce each instance from the pinned upstream source:

```python
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

source = TTFont('Nunito[wght].ttf')
for weight, name in [(400, 'Regular'), (700, 'Bold')]:
    font = instantiateVariableFont(
        source, {'wght': weight}, inplace=False, updateFontNames=True
    )
    font.save(f'Nunito-{name}.ttf')
```

## Source Sans 3

Unmodified static TrueType files from the official Adobe repository:

- Repository: https://github.com/adobe-fonts/source-sans
- Commit: `87b37a2daaed80fcb8e8ccb0085c4d72ddade12e`
- Files: `TTF/SourceSans3-Regular.ttf`, `TTF/SourceSans3-Bold.ttf`
- License: upstream `LICENSE.md`, bundled as `SourceSans3-OFL.txt`
