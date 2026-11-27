"""Check the Chinese resources that ship in CC Pocket. Run from the repository root."""
import json
import plistlib
import re
from pathlib import Path


def unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate localization key: {key}")
        result[key] = value
    return result


def read_catalog(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_keys)


def main():
    mobile = Path("apps/mobile")
    strings = mobile / "lib/l10n"
    template = read_catalog(strings / "app_ja.arb")
    chinese = read_catalog(strings / "app_zh.arb")
    for key, source in template.items():
        if key.startswith("@"):
            continue
        # An optional second line can be empty when the button label fits on one line.
        if key not in chinese or (source.strip() and not chinese[key].strip()):
            raise ValueError(f"Missing Simplified Chinese translation: {key}")

    ios = mobile / "ios/Runner"
    plist = plistlib.loads((ios / "Info.plist").read_bytes())
    permission_copy = (ios / "zh-Hans.lproj/InfoPlist.strings").read_text(encoding="utf-8")
    for key in plist:
        if key.endswith("UsageDescription"):
            pattern = rf'^"{re.escape(key)}"\s*=\s*"[^"]*[\u3400-\u9fff][^"]*"\s*;'
            if not re.search(pattern, permission_copy, re.MULTILINE):
                raise ValueError(f"Missing Chinese iOS permission explanation: {key}")

    catalog = read_catalog(Path("apps/menubar/CCPocketMenubar/Localizable.xcstrings"))
    placeholder = re.compile(r"%(?:@|lld)")
    for key, entry in catalog["strings"].items():
        unit = entry.get("localizations", {}).get("zh-Hans", {}).get("stringUnit", {})
        translation = unit.get("value", "").strip()
        if unit.get("state") != "translated" or not translation:
            raise ValueError(f"Missing Simplified Chinese menu item: {key}")
        if sorted(placeholder.findall(key)) != sorted(placeholder.findall(translation)):
            raise ValueError(f"Incorrect format placeholders in menu translation: {key}")
    print("Chinese Flutter, iOS permission and macOS menu bar catalogs are complete.")


if __name__ == "__main__":
    main()
