#!/usr/bin/env python3
"""Verify the prepared source: pinned upstream commits, applied patches and identical overlays."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'sources/Shipwright'


def git(tree, *args):
    return subprocess.check_output(['git', '-C', str(tree), *args], stderr=subprocess.DEVNULL)


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def overlays():
    pairs = [(ROOT / 'port/CMake/ios.cmake', SOURCE / 'CMake/ios.cmake')]
    pairs += [(f, SOURCE / 'soh/ios' / f.name) for f in sorted((ROOT / 'ios').iterdir()) if f.is_file()]
    icon = ROOT / 'assets/AppIcon.appiconset'
    pairs += [(f, SOURCE / 'soh/ios/Assets.xcassets/AppIcon.appiconset' / f.name)
              for f in sorted(icon.iterdir()) if f.is_file()]
    return pairs


def verify(root=ROOT, pristine=False):
    lock = json.loads((root / 'sources.lock.json').read_text())
    identities = []
    for component in lock['components']:
        tree = root / component['path']
        head = git(tree, 'rev-parse', 'HEAD').decode().strip()
        if head != component['commit']:
            raise ValueError(f"{component['name']}: revision mismatch (expected {component['commit']}, got {head})")
        for patch in component.get('patches', []):
            check = ['apply', '--check'] if pristine else ['apply', '--reverse', '--check']
            try:
                git(tree, *check, str(root / patch))
            except subprocess.CalledProcessError:
                state = 'apply cleanly to' if pristine else 'be applied in'
                raise ValueError(f"{component['name']}: {patch} does not {state} the checkout")
        identities.append({'name': component['name'], 'upstream': component['url'], 'commit': head,
                           'patches': {p: sha256(root / p) for p in component.get('patches', [])}})
    if not pristine:
        for source, destination in overlays():
            if not destination.exists() or source.read_bytes() != destination.read_bytes():
                raise ValueError(f"overlay differs from the checkout: {source.relative_to(root)}")
    return {'schema': 3, 'profile': 'pristine' if pristine else 'prepared', 'components': identities}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pristine', action='store_true', help='check pinned sources before patches are applied')
    args = parser.parse_args()
    try:
        print(json.dumps(verify(pristine=args.pristine), indent=2))
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'Source verification failed: {error}\n')
