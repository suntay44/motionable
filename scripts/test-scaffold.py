#!/usr/bin/env python3
"""Public scaffolding: names remain data and existing folders stay untouched."""
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="motionable-scaffold-") as temp:
    base = Path(temp)
    for i, name in enumerate(['Acme / Kitchen & Co.', 'App "Pro" \\path', '食譜']):
        film = base / f"film {i}"
        subprocess.run(['bash', str(root / 'scripts/new.sh'), str(film), name], check=True)
        assert (film / 'engine/VERSION').read_text().strip() == json.loads((root / '.claude-plugin/plugin.json').read_text())['version']
        source = (film / 'scenes/Film.swift').read_text()
        escaped = name.replace('\\', '\\\\').replace('"', '\\"')
        assert 'lines: ["' + escaped + '"]' in source, source
        assert name in (film / 'DIRECTION.md').read_text()
        assert '{{PRODUCT}}' not in source and '{{SLUG}}' not in source
        subprocess.run(['swiftc', '-frontend', '-parse', str(film / 'scenes/Film.swift')], check=True)
        before = (film / 'DIRECTION.md').read_bytes()
        assert subprocess.run(['bash', str(root / 'scripts/new.sh'), str(film), 'Replacement']).returncode != 0
        assert (film / 'DIRECTION.md').read_bytes() == before
    existing = base / 'existing'
    existing.mkdir()
    (existing / 'DIRECTION.md').write_text('user content')
    assert subprocess.run(['bash', str(root / 'scripts/new.sh'), str(existing), 'New']).returncode != 0
    assert (existing / 'DIRECTION.md').read_text() == 'user content'
    linked = base / 'linked'
    linked.symlink_to(base / 'absent')
    assert subprocess.run(['bash', str(root / 'scripts/new.sh'), str(linked), 'New']).returncode != 0
    assert not (base / 'absent').exists()
    invalid = base / 'invalid'
    assert subprocess.run(['bash', str(root / 'scripts/new.sh'), str(invalid), 'Bad\nName']).returncode != 0
    assert not invalid.exists()
print('scaffold: punctuation, Swift escaping, Unicode fallback and existing-folder preservation passed')
