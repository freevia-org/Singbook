param(
    [string]$OutputDirectory = "$(Split-Path -Parent $PSScriptRoot)\docs\play-store\assets",
    [string]$SourceScreenshotDirectory = "$(Split-Path -Parent $PSScriptRoot)\artifacts\singbook-e2e"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

function Get-BrandColor([string]$value) {
    return [System.Drawing.ColorTranslator]::FromHtml($value)
}

function Add-RoundedRectangle(
    [System.Drawing.Drawing2D.GraphicsPath]$Path,
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [float]$Radius
) {
    $diameter = $Radius * 2
    $Path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $Path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $Path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $Path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $Path.CloseFigure()
}

function New-FeatureGraphic([string]$Locale, [string]$LineOne, [string]$LineTwo, [string]$SupportLine) {
    $width = 1024
    $height = 500
    $bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, $width, $height),
        (Get-BrandColor '#E1EBEF'),
        (Get-BrandColor '#F4F0E5'),
        18.0
    )
    $graphics.FillRectangle($background, 0, 0, $width, $height)
    $background.Dispose()

    # Subtle edge color fields keep the composition warm and connected to both app themes.
    $edgeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(28, 51, 99, 133))
    $graphics.FillEllipse($edgeBrush, -135, 350, 290, 290)
    $graphics.FillEllipse($edgeBrush, 920, -170, 265, 265)
    $edgeBrush.Dispose()

    $fontCollection = [System.Drawing.Text.PrivateFontCollection]::new()
    $fontCollection.AddFontFile((Join-Path $repoRoot 'assets\fonts\SingbookSerif-Bold.ttf'))
    $wordmarkFont = [System.Drawing.Font]::new($fontCollection.Families[0], 82, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $displayFont = [System.Drawing.Font]::new($fontCollection.Families[0], 47, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $supportFont = [System.Drawing.Font]::new('Segoe UI', 22, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $navyBrush = [System.Drawing.SolidBrush]::new((Get-BrandColor '#102744'))
    $blueBrush = [System.Drawing.SolidBrush]::new((Get-BrandColor '#356789'))
    $amberBrush = [System.Drawing.SolidBrush]::new((Get-BrandColor '#F1B53B'))
    $singWidth = $graphics.MeasureString('Sing', $wordmarkFont).Width
    $graphics.DrawString('Sing', $wordmarkFont, $blueBrush, 70, 39)
    $graphics.DrawString('book', $wordmarkFont, $navyBrush, 70 + $singWidth - 31, 39)
    $sWidth = $graphics.MeasureString('S', $wordmarkFont).Width
    $iWidth = $graphics.MeasureString('i', $wordmarkFont).Width
    $graphics.FillEllipse($amberBrush, 70 + $sWidth + ($iWidth / 2) - 7, 52, 14, 14)
    $graphics.DrawString($LineOne, $displayFont, $navyBrush, 74, 204)
    $graphics.DrawString($LineTwo, $displayFont, $navyBrush, 74, 260)
    $graphics.DrawString($SupportLine, $supportFont, $blueBrush, 78, 373)

    # A chord-and-lyric sheet extends the wordmark's brand language without repeating the app icon.
    $cardShadow = [System.Drawing.Drawing2D.GraphicsPath]::new()
    Add-RoundedRectangle $cardShadow 553 58 398 386 28
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 16, 39, 68))
    $graphics.FillPath($shadowBrush, $cardShadow)
    $cardShadow.Dispose()
    $shadowBrush.Dispose()

    $cardPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    Add-RoundedRectangle $cardPath 544 48 398 386 28
    $cardBrush = [System.Drawing.SolidBrush]::new((Get-BrandColor '#FBF8EF'))
    $cardPen = [System.Drawing.Pen]::new((Get-BrandColor '#C9D6D4'), 2)
    $graphics.FillPath($cardBrush, $cardPath)
    $graphics.DrawPath($cardPen, $cardPath)
    $cardPath.Dispose()
    $cardBrush.Dispose()
    $cardPen.Dispose()

    $chordFont = [System.Drawing.Font]::new('Segoe UI', 24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $chordBrush = [System.Drawing.SolidBrush]::new((Get-BrandColor '#285A7A'))
    $lyricPen = [System.Drawing.Pen]::new((Get-BrandColor '#9CAFA8'), 5)
    $lyricPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $lyricPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawString('C', $chordFont, $chordBrush, 584, 93)
    $graphics.DrawString('G', $chordFont, $chordBrush, 795, 93)
    $graphics.DrawLine($lyricPen, 638, 143, 888, 143)
    $graphics.DrawString('Am', $chordFont, $chordBrush, 719, 169)
    $graphics.DrawLine($lyricPen, 590, 219, 735, 219)
    $graphics.DrawLine($lyricPen, 784, 219, 899, 219)
    $graphics.DrawString('F', $chordFont, $chordBrush, 608, 246)
    $graphics.DrawString('Dm', $chordFont, $chordBrush, 804, 246)
    $graphics.DrawLine($lyricPen, 657, 296, 891, 296)
    $graphics.DrawString('G', $chordFont, $chordBrush, 745, 321)
    $graphics.DrawLine($lyricPen, 590, 371, 710, 371)
    $graphics.DrawLine($lyricPen, 812, 371, 899, 371)

    $target = Join-Path $OutputDirectory "feature-graphic-$Locale.png"
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)

    $amberBrush.Dispose()
    $wordmarkFont.Dispose()
    $lyricPen.Dispose()
    $chordFont.Dispose()
    $chordBrush.Dispose()
    $displayFont.Dispose()
    $supportFont.Dispose()
    $fontCollection.Dispose()
    $navyBrush.Dispose()
    $blueBrush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

# Google Play's listing icon is a separate 512px PNG, not the launcher mipmap.
$iconSource = [System.Drawing.Image]::FromFile((Join-Path $repoRoot 'assets\branding\singbook-icon.png'))
$icon = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$iconGraphics = [System.Drawing.Graphics]::FromImage($icon)
$iconGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$iconGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$iconGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$iconGraphics.DrawImage($iconSource, 0, 0, 512, 512)
$icon.Save((Join-Path $OutputDirectory 'app-icon-512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$iconGraphics.Dispose()
$icon.Dispose()
$iconSource.Dispose()

New-FeatureGraphic 'en' 'Your songs,' 'ready to sing.' 'Lyrics · chords · setlists'
New-FeatureGraphic 'bg' 'Песните ви,' 'готови за пеене.' 'Текстове · акорди · сетлисти'
New-FeatureGraphic 'uk' 'Ваші пісні,' 'готові до співу.' 'Тексти · акорди · сетлисти'

# These are unaltered app screens from the completed device journey, cropped only to Play's 9:16 portrait canvas.
$screens = @(
    @{ Source = '21_home_recent_populated-device.png'; Target = 'phone-01-library.png'; Y = 120 },
    @{ Source = '18_reader_chords-device.png'; Target = 'phone-02-reader.png'; Y = 120 },
    @{ Source = '02_source_preview-device.png'; Target = 'phone-03-source-preview.png'; Y = 120 },
    @{ Source = '24_settings_light-device.png'; Target = 'phone-04-themes.png'; Y = 120 }
)
foreach ($screen in $screens) {
    $sourcePath = Join-Path $SourceScreenshotDirectory $screen.Source
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    if ($source.Width -ne 1080 -or $source.Height -lt ($screen.Y + 1920)) {
        $source.Dispose()
        throw "Unexpected source screenshot geometry: $sourcePath"
    }
    $crop = [System.Drawing.Rectangle]::new(0, $screen.Y, 1080, 1920)
    $result = [System.Drawing.Bitmap]::new(1080, 1920, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $resultGraphics = [System.Drawing.Graphics]::FromImage($result)
    $resultGraphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 1080, 1920), $crop, [System.Drawing.GraphicsUnit]::Pixel)
    $result.Save((Join-Path $OutputDirectory $screen.Target), [System.Drawing.Imaging.ImageFormat]::Png)
    $resultGraphics.Dispose()
    $result.Dispose()
    $source.Dispose()
}

Get-ChildItem -LiteralPath $OutputDirectory -File | Select-Object Name, Length
