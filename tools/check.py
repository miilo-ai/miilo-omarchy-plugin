"""Portable repository checks; native Omarchy remains the runtime authority."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import re


def safe_file(root, name):
    path = PurePosixPath(name)
    if path.is_absolute() or not path.parts or '..' in path.parts or '\\' in name:
        raise ValueError(f'Unsafe repository path: {name}')
    candidate = root.joinpath(*path.parts)
    current = root
    for part in path.parts:
        current = current / part
        if current.is_symlink():
            raise ValueError(f'Symlink path: {name}')
    if not candidate.is_file():
        raise ValueError(f'Missing file: {name}')
    return candidate


def check(root):
    manifest = json.loads((root / 'manifest.json').read_text())
    for field in ['schemaVersion', 'id', 'name', 'version', 'author', 'license', 'description', 'kinds', 'entryPoints']:
        if not manifest.get(field):
            raise ValueError(f'Missing manifest field: {field}')
    if manifest['schemaVersion'] != 1 or manifest['id'] != 'io.miilo.bar':
        raise ValueError('Unexpected schema or plugin identity')
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?', manifest['version']):
        raise ValueError('Expected semantic plugin version')
    if manifest['kinds'] != ['bar-widget'] or set(manifest['entryPoints']) != {'barWidget'}:
        raise ValueError('Only the supported bar-widget entry may be declared')
    safe_file(root, manifest['entryPoints']['barWidget'])
    if 'clonedFrom' in manifest.get('omarchy', {}):
        raise ValueError('Clone-only identity must not ship')
    for path in root.rglob('*'):
        if '.git' not in path.relative_to(root).parts and path.is_symlink():
            raise ValueError(f'Symlink in plugin repository: {path.relative_to(root)}')
    lock = json.loads((root / 'sources.lock.json').read_text())
    if not re.fullmatch(r'[a-f0-9]{40}', lock['revision']):
        raise ValueError('Source revision must be an immutable commit')
    pinned = set()
    for record in lock['files']:
        name = record['path']
        if name in pinned:
            raise ValueError(f'Duplicate provenance path: {name}')
        pinned.add(name)
        digest = hashlib.sha256(safe_file(root, name).read_bytes()).hexdigest()
        if digest != record['sha256']:
            raise ValueError(f'Unreviewed source drift: {name}; update provenance intentionally')
    for required in ['LICENSE', 'desktop/runtime/LICENSE', 'desktop/runtime/UPSTREAM.md', 'desktop/70-miilo-fleet.owl']:
        safe_file(root, required)
        if required not in pinned:
            raise ValueError(f'Unpinned required asset: {required}')
    for path in (root / 'desktop').rglob('*'):
        if not path.is_file():
            continue
        name = str(path.relative_to(root))
        if name not in pinned:
            raise ValueError(f'Unpinned runtime asset: {name}')
        if path.suffix not in {'.qml', '.js', '.owl'}:
            continue
        text = path.read_text()
        if re.search(r'[\"\'](?:quickshell|qs)[\"\']', text):
            raise ValueError(f'Native plugin must not launch a second shell: {name}')
        for item in re.findall(r'^import\s+"([^"]+)"', text, re.M):
            imported = path.parent / item
            if not imported.exists() or not imported.resolve().is_relative_to(root.resolve()):
                raise ValueError(f'Missing or escaped local import in {name}: {item}')
    print('Manifest, local imports, source hashes, licenses and single-shell source checks passed.')
    print('Native Omarchy validation and QML runtime acceptance remain separate gates.')


if __name__ == '__main__':
    check(Path(__file__).resolve().parents[1])
