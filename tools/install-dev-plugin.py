"""Install checked local native UI with backups; never enroll sources or enable services."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib


def version(binary, expected):
    result = subprocess.run([str(binary), '--version'], capture_output=True, text=True, check=True)
    if result.stdout.strip() != expected:
        raise ValueError(f'{binary.name} must report {expected!r}; rebuild with --rebuild first')


def atomic_copy(source, destination, executable=False):
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix='.miilo-copy-', dir=destination.parent)
    try:
        with os.fdopen(descriptor, 'wb') as stream:
            stream.write(source.read_bytes())
        os.chmod(name, 0o755 if executable else 0o644)
        os.replace(name, destination)
    finally:
        Path(name).unlink(missing_ok=True)


def install(args):
    root = Path(__file__).resolve().parents[1]
    helper_manifest = tomllib.loads((root.parent / 'miilo-owl-widgets/helper/Cargo.toml').read_text())
    cli_manifest = tomllib.loads((root.parent / 'miilo-cli/Cargo.toml').read_text())
    version(args.helper, 'miilo-owl ' + helper_manifest['package']['version'])
    version(args.local, 'miilo-local ' + cli_manifest['workspace']['package']['version'])
    target = args.plugin_dir
    if target.is_symlink() or (target / '.git').exists():
        raise ValueError('Installed plugin is a symlink/Git checkout; reconcile that checkout before replacing it')
    if target.exists():
        manifest = json.loads((target / 'manifest.json').read_text())
        if manifest.get('id') != 'io.miilo.bar':
            raise ValueError('Refusing to replace an unrelated plugin')
    files = []
    for folder in ['ui', 'vendor', 'assets']:
        for source in (root / folder).rglob('*'):
            if source.is_symlink():
                raise ValueError('Source package must not contain symlinks')
            if source.is_file():
                files.append(source.relative_to(root))
    files += [Path(name) for name in ['LICENSE', 'sources.lock.json', 'manifest.json']]
    # Never follow an installed file/directory symlink while overlaying managed UI.
    for relative in files:
        for candidate in [target / relative, *(target / relative).parents]:
            if candidate == target.parent:
                break
            if candidate.is_symlink():
                raise ValueError('Installed package contains a symlink in a managed path')
    args.state_dir.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix='native-', dir=args.state_dir))
    os.chmod(backup, 0o700)
    print(f'Backup: {backup}', flush=True)
    if target.exists():
        shutil.copytree(target, backup / 'io.miilo.bar', symlinks=True)
    binaries = [('miilo-owl', args.helper), ('miilo-local', args.local)]
    if args.install_binaries:
        for name, _ in binaries:
            existing = args.bin_dir / name
            if existing.exists():
                shutil.copy2(existing, backup / name)
    target.mkdir(parents=True, exist_ok=True)
    # Write manifest last: the old flat entry remains valid until new UI exists.
    for relative in files:
        atomic_copy(root / relative, target / relative)
    if args.install_binaries:
        for name, source in binaries:
            atomic_copy(source, args.bin_dir / name, executable=True)
    for relative in files:
        if (target / relative).read_bytes() != (root / relative).read_bytes():
            raise ValueError(f'Installed file mismatch: {relative}')
    evidence = {
        'plugin': 'io.miilo.bar',
        'sourceCommit': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
        'sourceDirty': bool(subprocess.check_output(['git', '-C', str(root), 'status', '--porcelain'], text=True).strip()),
        'files': {str(p): hashlib.sha256((root / p).read_bytes()).hexdigest() for p in files},
        'binaries': {name: hashlib.sha256(source.read_bytes()).hexdigest() for name, source in binaries},
    }
    (backup / 'installed.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print('Installed canonical native io.miilo.bar; legacy dashboard/desktop and observation data preserved.')


def main():
    home = Path.home()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plugin-dir', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME', home / '.config')) / 'omarchy/plugins/io.miilo.bar')
    parser.add_argument('--bin-dir', type=Path, default=home / '.local/bin')
    parser.add_argument('--state-dir', type=Path, default=Path(os.environ.get('XDG_STATE_HOME', home / '.local/state')) / 'miilo/plugin-backups')
    parser.add_argument('--helper', type=Path, required=True)
    parser.add_argument('--local', type=Path, required=True)
    parser.add_argument('--install-binaries', action='store_true')
    try:
        install(parser.parse_args())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, f'Miilo install stopped: {error}\n')


if __name__ == '__main__':
    main()
