"""Render CC Pocket launcher assets and its Flutter-compatible icon font."""
import hashlib
from io import BytesIO
from pathlib import Path
import re
import sys
import tarfile
import urllib.request
import zipfile

from fontTools.pens.areaPen import AreaPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw

LUCIDE_URL = 'https://pub.dev/api/archives/flutter_lucide-1.78.0.tar.gz'
LUCIDE_SHA256 = 'a6d3b5a1c4c7d14886b0827d95e8db3072d824c16fda5768254fbca8e120c708'
SIZE = 1024


def download(url):
    with urllib.request.urlopen(url, timeout=45) as stream:
        return stream.read()


def icon_definitions(source):
    pairs = re.findall(r'static const IconData (\w+) =\s*IconData\(\s*0x([\da-fA-F]+)', source)
    return {name: int(value, 16) for name, value in pairs}


def glyph_recording(glyphs, name):
    pen = DecomposingRecordingPen(glyphs)
    glyphs[name].draw(pen)
    return pen


def bounds(glyphs, name):
    pen = BoundsPen(glyphs)
    glyphs[name].draw(pen)
    return pen.bounds


def active_outline(recording, glyphs):
    pen = DecomposingRecordingPen(glyphs)
    contours = []
    points = []
    for operation in recording.value:
        points.append(operation)
        if operation[0] == 'closePath':
            area = AreaPen(glyphs)
            for method, arguments in points:
                getattr(area, method)(*arguments)
            contours.append((area.value, points))
            points = []
    if not contours or points:
        return recording
    largest = max(contours, key=lambda contour: abs(contour[0]))[0]
    # A filled active star, heart, or pin retains its outer silhouette.
    for area, outline in contours:
        if area * largest > 0:
            pen.value.extend(outline)
    return pen


def build_font(mobile, flutter):
    icons_source = flutter / 'packages/flutter/lib/src/material/icons.dart'
    material = icon_definitions(icons_source.read_text())
    material_dir = flutter / 'bin/cache/artifacts/material_fonts'
    base = TTFont(material_dir / 'MaterialIcons-Regular.otf')
    base_glyphs = base.getGlyphSet()
    base_cmap = base.getBestCmap()
    cff = base['CFF '].cff
    charstrings = cff.topDictIndex[0].CharStrings

    payload = download(LUCIDE_URL)
    if hashlib.sha256(payload).hexdigest() != LUCIDE_SHA256:
        raise ValueError('Lucide source package checksum mismatch')
    with tarfile.open(fileobj=BytesIO(payload), mode='r:gz') as source:
        icons = icon_definitions(source.extractfile('lib/src/flutter_lucide.dart').read().decode())
        lucide = TTFont(BytesIO(source.extractfile('lib/fonts/lucide.ttf').read()))
        lucide_license = source.extractfile('lib/fonts/LICENSE').read()
    glyphs = lucide.getGlyphSet()
    lucide_cmap = lucide.getBestCmap()

    mapping = {}
    for line in Path(__file__).with_name('glyphs.txt').read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        new, *old = line.split()
        for name in old:
            if name in mapping:
                raise ValueError(f'Duplicate icon mapping: {name}')
            mapping[name] = new

    used = set()
    for path in (mobile / 'lib').rglob('*.dart'):
        used.update(re.findall(r'\bIcons\.(\w+)', path.read_text()))
    if missing := used - mapping.keys():
        raise ValueError(f'Icons missing from the refresh: {", ".join(sorted(missing))}')

    old_circle = bounds(base_glyphs, base_cmap[material['circle']])
    new_circle = bounds(glyphs, lucide_cmap[icons['circle']])
    scale = (old_circle[2] - old_circle[0]) / (new_circle[2] - new_circle[0])
    y_offset = (old_circle[1] + old_circle[3] - scale * (new_circle[1] + new_circle[3])) / 2
    x_padding = (base_glyphs[base_cmap[material['circle']]].width - scale *
                 glyphs[lucide_cmap[icons['circle']]].width) / 2

    mapped_codepoints = {}
    for old, new in mapping.items():
        codepoint = material[old]
        if codepoint in mapped_codepoints and mapped_codepoints[codepoint] != new:
            raise ValueError(f'Conflicting replacement for Flutter glyph {old}')
        mapped_codepoints[codepoint] = new
        old_name = base_cmap[codepoint]
        new_name = lucide_cmap[icons[new]]
        original = charstrings[old_name]
        drawing = glyph_recording(glyphs, new_name)
        if old in {'favorite', 'star', 'push_pin'}:
            drawing = active_outline(drawing, glyphs)
        width = base_glyphs[old_name].width
        output = T2CharStringPen(width, None)
        drawing.replay(TransformPen(output, (scale, 0, 0, scale, x_padding, y_offset)))
        charstrings[old_name] = output.getCharString(
            private=original.private, globalSubrs=cff.GlobalSubrs,
        )

    font_dir = mobile / 'assets/fonts/icons'
    font_dir.mkdir(parents=True, exist_ok=True)
    base.save(font_dir / 'CCPocketIcons.otf')
    (font_dir / 'LICENSE-LUCIDE.txt').write_bytes(lucide_license)
    material_license = (material_dir / 'MaterialIcons_LICENSE.txt')
    if not material_license.is_file():
        version = (flutter / 'bin/internal/material_fonts.version').read_text().strip()
        with zipfile.ZipFile(BytesIO(download('https://storage.googleapis.com/' + version))) as archive:
            material_license_bytes = archive.read('MaterialIcons_LICENSE.txt')
    else:
        material_license_bytes = material_license.read_bytes()
    (font_dir / 'LICENSE-MATERIAL.txt').write_bytes(material_license_bytes)

    refreshed = TTFont(font_dir / 'CCPocketIcons.otf')
    if refreshed.getBestCmap() != base_cmap:
        raise ValueError('Flutter codepoints changed during replacement')
    print(f'Refreshed {len(used)} application icon references and preserved Flutter codepoint coverage.')


def logo(background, panel, border, first, second, foreground_only=False,
         notification=False):
    image = Image.new('RGBA', (SIZE, SIZE), background)
    draw = ImageDraw.Draw(image)
    if not foreground_only:
        draw.rounded_rectangle((108, 108, 916, 916), radius=186, fill=panel)
        draw.rounded_rectangle((108, 108, 916, 916), radius=186, outline=border, width=3)
    if notification:
        radius, center_a, center_b, width = 168, 386, 638, 62
    elif foreground_only:
        radius, center_a, center_b, width = 132, 415, 609, 48
    else:
        radius, center_a, center_b, width = 172, 394, 630, 60
    # Render two interlocking, open Cs with rounded tips at icon scale.
    for center, color in ((center_a, first), (center_b, second)):
        draw.arc((center-radius, 512-radius, center+radius, 512+radius),
                 43, 317, fill=color, width=width)
        for sign in (-1, 1):
            rim = radius - width / 2
            tip_x = center + rim * 0.73135
            tip_y = 512 + sign * rim * 0.68200
            cap = width / 2
            draw.ellipse((tip_x-cap, tip_y-cap, tip_x+cap, tip_y+cap), fill=color)
    return image


def write_png(path, image, opaque=False):
    size = Image.open(path).size if path.is_file() else (SIZE, SIZE)
    image = image.resize(size, Image.Resampling.LANCZOS)
    if opaque:
        image = image.convert('RGB')
    image.save(path, format='PNG', optimize=True)


def project_launchers(mobile):
    standard = ('#283444', '#344258', '#5A697D', '#D2DCE9', '#E9DFD0')
    light = ('#DAD6CD', '#EEEBE4', '#C6C4C1', '#536578', '#384B61')
    copper = ('#263330', '#33443E', '#597369', '#D09C78', '#B9D1BE')
    schemes = [standard, light, copper]
    solid = [logo(*colors) for colors in schemes]
    adaptive = [logo((0, 0, 0, 0), *colors[1:], foreground_only=True) for colors in schemes]
    notification = logo((0, 0, 0, 0), None, None, 'white', 'white',
                        foreground_only=True, notification=True)
    variants = ['icon.png', 'icon_light_outline.png', 'icon_pro_copper_emerald.png']

    for variant, image in zip(variants, solid):
        path = mobile / 'assets' / variant
        image.convert('RGB').save(path, format='PNG', optimize=True)
    write_png(mobile / 'assets/icon_foreground.png', adaptive[0])
    write_png(mobile / 'assets/icon_notification.png', notification)

    ios = mobile / 'ios/Runner/Assets.xcassets'
    sets = ['AppIcon', 'SupporterLightOutline', 'SupporterProCopperEmerald']
    for name, image in zip(sets, solid):
        for path in (ios / f'{name}.appiconset').glob('*.png'):
            write_png(path, image, opaque=True)
    macos = mobile / 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    for path in macos.glob('*.png'):
        write_png(path, solid[0], opaque=True)
    res = mobile / 'android/app/src/main/res'
    standard_icons = {'launcher_icon', 'ic_launcher'}
    alternate_icons = ['ic_launcher_supporter_light_outline', 'ic_launcher_supporter_pro_copper_emerald']
    for path in res.glob('mipmap-*/*.png'):
        if path.stem in standard_icons:
            write_png(path, solid[0], opaque=True)
        elif path.stem in alternate_icons:
            write_png(path, solid[1 + alternate_icons.index(path.stem)], opaque=True)
    for path in res.glob('drawable-*/*.png'):
        if path.stem == 'ic_launcher_foreground':
            write_png(path, adaptive[0])
        elif path.stem == 'ic_notification':
            write_png(path, notification)
        elif path.stem.removesuffix('_foreground') in alternate_icons:
            index = alternate_icons.index(path.stem.removesuffix('_foreground'))
            write_png(path, adaptive[index + 1])
    web = mobile / 'web'
    for path in [web / 'favicon.png', *(web / 'icons').glob('*.png')]:
        write_png(path, solid[0], opaque=True)
    windows = mobile / 'windows/runner/resources/app_icon.ico'
    with Image.open(windows) as previous:
        sizes = list(previous.ico.sizes())
    solid[0].save(windows, format='ICO', sizes=sizes)
    for path in (mobile / 'fastlane/metadata/android').glob('*/images/icon.png'):
        write_png(path, solid[0], opaque=True)
    print('Rendered iOS, Android, macOS, Windows and web launcher assets.')


if __name__ == '__main__':
    mobile = Path(sys.argv[1])
    flutter = Path(sys.argv[2])
    build_font(mobile, flutter)
    project_launchers(mobile)
