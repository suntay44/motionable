#!/usr/bin/env python3
"""Optional local voice preparation. Rendering never invokes this tool."""
import argparse
import array
import contextlib
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import wave

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
CACHE = Path(os.environ.get('MOTIONABLE_VOICE_CACHE', '~/Library/Caches/motionable-voice')).expanduser().resolve()
RELEASE = 'https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/'
MISAKI = 'https://raw.githubusercontent.com/hexgrad/misaki/fba1236595f2d2bf21d414ba6e57d25256afada3/misaki/data/'
ASSETS = [
    ('kokoro-v1.0.int8.onnx', RELEASE, '6e742170d309016e5891a994e1ce1559c702a2ccd0075e67ef7157974f6406cb'),
    ('voices-v1.0.bin', RELEASE, 'bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d'),
    ('us_gold.json', MISAKI, 'dc414872a49a28ae6c141463d502fd945f3b2fde040484fdc47d00cc4612686f'),
    ('us_silver.json', MISAKI, 'de8f67be911bb6c659187b4a65fd966b6a30e56350e0f790d763210b053ac475'),
    ('onnxruntime-osx-arm64-1.24.2.tgz', 'https://github.com/microsoft/onnxruntime/releases/download/v1.24.2/',
     '0af4fa503e8ea285245b47ee42d0a7461b8156a81270857da0c1d4ecf858abde'),
]


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for part in iter(lambda: f.read(1024 * 1024), b''):
            h.update(part)
    return h.hexdigest()


def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + '\n').encode()


def atomic(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix='.' + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp): os.unlink(temp)


@contextlib.contextmanager
def lock(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a') as f:
        try: fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: raise ValueError('Another voice operation is running here; wait for it to finish.')
        yield


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, **kwargs)


def backend_id():
    names = ['infer.cpp', 'phonemes.swift', 'KokoroPhonemizer.swift', 'KokoroTokens.swift',
             'convert_model.py', 'onnx_wire.py', 'make_voice.py', 'make_lexicon.py']
    return 'kokoro-v1-' + hashlib.sha256(json_bytes(ASSETS) + ''.join(digest(HERE / n) for n in names).encode()).hexdigest()[:16]


def installed():
    target = CACHE / backend_id()
    try:
        hashes = json.loads((target / 'installed.json').read_text())
        if not hashes or any(digest(target / p) != h for p, h in hashes.items()): return None
    except (OSError, ValueError): return None
    return target


def setup(args):
    if platform.system() != 'Darwin' or platform.machine() != 'arm64':
        raise ValueError('Local Kokoro currently supports Apple Silicon Macs. Supplied recordings work on other supported Macs.')
    CACHE.mkdir(parents=True, exist_ok=True)
    with lock(CACHE / 'setup.lock'):
        if installed():
            print('Kokoro is ready; nothing to download.'); return
        if shutil.disk_usage(CACHE).free < 1024 ** 3:
            raise ValueError('Allow at least 1 GB free for setup, unpacking and compilation.')
        downloads = CACHE / 'downloads'; downloads.mkdir(exist_ok=True)
        for name, base, expected in ASSETS:
            dest = downloads / name
            if dest.exists() and digest(dest) == expected: continue
            source = Path(args.asset_source).expanduser() / name if args.asset_source else None
            temp = dest.with_suffix(dest.suffix + '.part')
            try:
                if source and source.is_file() and digest(source) == expected:
                    print('Reusing verified ' + name, flush=True); shutil.copyfile(source, temp)
                else:
                    print('Downloading ' + name, flush=True)
                    with urllib.request.urlopen(base + name, timeout=60) as r, temp.open('wb') as f:
                        shutil.copyfileobj(r, f)
                if digest(temp) != expected: raise ValueError('Checksum mismatch: ' + name)
                os.replace(temp, dest)
            finally:
                if temp.exists(): temp.unlink()
        with tempfile.TemporaryDirectory(prefix='.setup-', dir=CACHE) as work:
            work = Path(work)
            with tarfile.open(downloads / ASSETS[-1][0]) as archive:
                # Archive is checksum-pinned; still reject escaping members/links.
                for member in archive.getmembers():
                    candidate = (work / member.name).resolve()
                    if not str(candidate).startswith(str(work) + os.sep): raise ValueError('Unsafe archive member')
                    if member.issym() or member.islnk():
                        link = (candidate.parent / member.linkname).resolve()
                        if not str(link).startswith(str(work) + os.sep): raise ValueError('Unsafe archive link')
                archive.extractall(work)
            runtime = work / 'onnxruntime-osx-arm64-1.24.2'
            run([sys.executable, HERE / 'convert_model.py', downloads / ASSETS[0][0], work / 'model.onnx'])
            run([sys.executable, HERE / 'make_voice.py', downloads / ASSETS[1][0], 'af_heart', work / 'voice.bin'])
            run([sys.executable, HERE / 'make_lexicon.py', downloads / ASSETS[2][0], downloads / ASSETS[3][0], work / 'lexicon.tsv'])
            run(['swiftc', '-O', '-enable-bare-slash-regex', HERE / 'KokoroPhonemizer.swift', HERE / 'KokoroTokens.swift', HERE / 'phonemes.swift', '-o', work / 'phonemes'])
            run(['clang++', '-std=c++17', '-O2', HERE / 'infer.cpp', '-I' + str(runtime / 'include'),
                 '-L' + str(runtime / 'lib'), '-lonnxruntime', '-Wl,-rpath,@executable_path/onnxruntime-osx-arm64-1.24.2/lib', '-o', work / 'infer'])
            # Hash actual installed files so a damaged cache isn't reported as ready.
            hashes = {str(p.relative_to(work)): digest(p) for p in work.rglob('*') if p.is_file()}
            atomic(work / 'installed.json', json_bytes(hashes))
            target = CACHE / backend_id()
            if target.exists():
                retired = CACHE / (backend_id() + '.damaged')
                if retired.exists(): shutil.rmtree(retired)
                os.replace(target, retired)
            os.replace(work, target)
        total = sum(p.stat().st_size for p in target.rglob('*') if p.is_file())
        print('Kokoro ready: %.1f MB installed, plus reusable download cache. %s' % (total / 1e6, target))


def audio_info(path):
    # Audio import uses macOS frameworks only; no voice setup is needed.
    sources = [HERE / 'audio.swift', ROOT / 'engine/Narration.swift']
    key = hashlib.sha256(''.join(digest(p) for p in sources).encode()).hexdigest()[:16]
    binary = CACHE / ('audio-' + key)
    CACHE.mkdir(parents=True, exist_ok=True)
    with lock(CACHE / 'audio-build.lock'):
        if not binary.exists():
            with tempfile.TemporaryDirectory(dir=CACHE) as work:
                temp = Path(work) / 'audio'
                run(['swiftc', '-O', *sources, '-o', temp])
                os.replace(temp, binary)
    return json.loads(run([binary, path], stdout=subprocess.PIPE).stdout)


def local_path(film, path):
    path = Path(path).expanduser().resolve()
    try: path.relative_to(film)
    except ValueError: raise ValueError('Script and take must be inside the film directory: ' + str(path))
    return path


def script_data(path, content=None):
    data = json.loads(path.read_bytes() if content is None else content)
    if not isinstance(data, dict): raise ValueError('Script must be a JSON object with phrases.')
    phrases = data.get('phrases', [])
    if not isinstance(phrases, list) or not phrases or len(phrases) > 100:
        raise ValueError('script.json needs 1–100 phrases.')
    ids = set()
    for p in phrases:
        if not isinstance(p, dict): raise ValueError('Each phrase must be a JSON object.')
        if not isinstance(p.get('id'), str) or not p['id'] or p['id'] in ids: raise ValueError('Each phrase needs a unique id.')
        ids.add(p['id'])
        for key in ['text', 'spoken']:
            value = p.get(key, p.get('text'))
            if not isinstance(value, str) or not value.strip() or len(value) > 4000: raise ValueError('Each phrase needs nonempty, bounded text/spoken words.')
        pause = p.get('pauseAfter', 0.25)
        if not isinstance(pause, (int, float)) or not math.isfinite(pause) or not 0 <= pause <= 5: raise ValueError('pauseAfter must be 0–5 seconds.')
    return data


def manifest(film, work, audio, script, phrases, source, offset, gain, duck):
    info = audio_info(audio)
    if info['peak'] > 1: raise ValueError('Audio exceeds full scale. Supply an unclipped take or repair it explicitly before import.')
    if not (math.isfinite(offset) and offset >= 0 and math.isfinite(gain) and 0 <= gain <= 2 and math.isfinite(duck) and 0 <= duck <= 24):
        raise ValueError('Invalid offset/gain/ducking.')
    if not isinstance(phrases, list) or not 1 <= len(phrases) <= 100:
        raise ValueError('Candidate needs 1–100 caption phrases.')
    previous = 0
    ids = set()
    for p in phrases:
        if not isinstance(p, dict) or not isinstance(p.get('id'), str) or not p['id'] or p['id'] in ids:
            raise ValueError('Candidate phrases need unique, nonempty ids.')
        ids.add(p['id'])
        if not isinstance(p.get('text'), str) or not p['text'].strip():
            raise ValueError('Candidate phrases need nonempty caption text.')
        a, z = p['start'], p['end']
        if not (math.isfinite(a) and math.isfinite(z) and a >= previous and z > a and z <= info['duration'] + 0.0001):
            raise ValueError('Phrase times must be ordered, non-overlapping and inside the audio.')
        previous = z
    return dict(version=1, audio=str(audio.relative_to(film)), audioSHA256=digest(audio),
                script=str(script.relative_to(film)), scriptSHA256=digest(script), duration=info['duration'],
                offset=offset, gain=gain, duckDB=duck, phrases=phrases, source=source,
                timing='phrase boundaries; review before approval')


def existing_candidate(film, script, source, args):
    takes = film / 'assets/voice/takes'
    for path in sorted(takes.glob('*/narration.json')):
        try:
            m = json.loads(path.read_text())
            if (m['source'] == source and m['script'] == str(script.relative_to(film))
                    and m['scriptSHA256'] == digest(script) and m['offset'] == args.offset
                    and m['gain'] == args.gain and m['duckDB'] == args.duck_db
                    and digest(local_path(film, film / m['audio'])) == m['audioSHA256']):
                print('Reusing candidate: ' + str(path))
                print('Preview: ' + str(film / m['audio']))
                return True
        except (OSError, ValueError, KeyError, TypeError):
            continue
    return False


def prepare(args):
    film = Path(args.film).expanduser().resolve()
    if not (math.isfinite(args.offset) and args.offset >= 0 and math.isfinite(args.gain) and 0 <= args.gain <= 2 and math.isfinite(args.duck_db) and 0 <= args.duck_db <= 24):
        raise ValueError('Invalid offset/gain/ducking.')
    if not (film / 'scenes').is_dir(): raise ValueError('Expected a motionable film directory with scenes/.')
    script = local_path(film, args.script)
    script_bytes = script.read_bytes()
    script_hash = hashlib.sha256(script_bytes).hexdigest()
    data = script_data(script, script_bytes)
    source = dict(kind='kokoro', voice='af_heart', language='en-US', backend=backend_id())
    if args.command == 'generate' and existing_candidate(film, script, source, args): return
    voice = film / 'assets/voice'; voice.mkdir(parents=True, exist_ok=True)
    takes = voice / 'takes'; takes.mkdir(exist_ok=True)
    with lock(voice / '.prepare.lock'):
        # Candidates never replace the currently approved manifest, even on failure.
        with tempfile.TemporaryDirectory(prefix='.take-', dir=takes) as temporary:
            work = Path(temporary)
            if args.command == 'generate':
                backend = installed()
                if not backend: raise ValueError('Kokoro is not installed or needs repair. Run voice.sh status, then voice.sh setup when local generation is selected.')
                for p in data['phrases']:
                    spoken = p.get('spoken', p['text'])
                    if not any(c.isalpha() for c in spoken):
                        raise ValueError('Write spoken words for phrase ' + p['id'])
                    if any(c.isdigit() for c in spoken) or any(c in spoken for c in '$%&@/+=<>'):
                        raise ValueError('Write numbers, URLs and symbols as words in spoken for phrase ' + p['id'])
                snapshot = work / 'script.json'
                snapshot.write_bytes(script_bytes)
                result = json.loads(run([backend / 'phonemes', backend / 'lexicon.tsv', snapshot], stdout=subprocess.PIPE).stdout)
                snapshot.unlink()
                for p in result:
                    if p['unknown']: raise ValueError('Unknown pronunciation in %s: %s. Use a reviewed spoken spelling.' % (p['id'], ', '.join(p['unknown'])))
                    if not 1 <= len(p['tokens']) <= 510: raise ValueError('Phrase %s is empty or too long; split at a sentence boundary.' % p['id'])
                tokenfile = work / 'tokens.txt'
                tokenfile.write_text('\n'.join(str(len(p['tokens'])) + ' ' + ' '.join(map(str, p['tokens'])) for p in result))
                print('Generating %d phrases locally with Kokoro af_heart…' % len(result), flush=True)
                run([backend / 'infer', backend / 'model.onnx', backend / 'voice.bin', tokenfile, work / 'part-'])
                samples = array.array('h'); phrases = []
                for i, p in enumerate(data['phrases']):
                    raw = array.array('f'); raw.frombytes((work / ('part-%d.f32' % i)).read_bytes())
                    if not raw or any(not math.isfinite(v) for v in raw): raise ValueError('Invalid generated samples.')
                    if len(samples) + len(raw) > 600 * 24000: raise ValueError('Narration must be at most ten minutes.')
                    start = len(samples) / 24000
                    # Keep generated breaths and quiet edges; playback gain belongs to the mixer.
                    phrases.append(dict(id=p['id'], text=p['text'], start=start, end=start + len(raw) / 24000))
                    # The model should be within full scale; reject instead of silently distorting it.
                    if max(map(abs, raw)) > 1: raise ValueError('Generated take clips; choose another take.')
                    samples.extend(int(v * 32767) for v in raw)
                    if i < len(result) - 1: samples.extend([0] * round(p.get('pauseAfter', 0.25) * 24000))
                audio = work / 'narration.wav'
                with wave.open(str(audio), 'wb') as output:
                    output.setnchannels(1); output.setsampwidth(2); output.setframerate(24000); output.writeframes(samples.tobytes())
                source = dict(kind='kokoro', voice='af_heart', language='en-US', backend=backend_id())
                for extra in work.glob('part-*.f32'): extra.unlink()
                tokenfile.unlink()
            else:
                supplied = Path(args.audio).expanduser().resolve()
                if supplied.suffix.lower() not in ('.wav', '.m4a', '.mp3', '.aif', '.aiff', '.caf'):
                    raise ValueError('Supply WAV, M4A, MP3, AIFF or CAF audio.')
                audio = work / ('narration' + supplied.suffix.lower()); shutil.copyfile(supplied, audio)
                phrases = []
                for p in data['phrases']:
                    if 'start' not in p or 'end' not in p: raise ValueError('Imported phrases need reviewed start/end seconds in script.json.')
                    phrases.append(dict(id=p['id'], text=p['text'], start=float(p['start']), end=float(p['end'])))
                source = dict(kind='import')
            m = manifest(film, work, audio, script, phrases, source, args.offset, args.gain, args.duck_db)
            if m['scriptSHA256'] != script_hash or digest(script) != script_hash:
                raise ValueError('Script changed during preparation. Prepare a new take from the current words.')
            identity = hashlib.sha256(json_bytes({**m, 'audio': audio.name})).hexdigest()[:24]
            destination = takes / identity
            m['audio'] = str((destination / audio.name).relative_to(film))
            atomic(work / 'narration.json', json_bytes(m))
            if destination.exists():
                # Same identity should mean same audio and manifest; never replace user-edited takes.
                if digest(destination / audio.name) != m['audioSHA256'] or (destination / 'narration.json').read_bytes() != json_bytes(m):
                    raise ValueError('Existing take differs; preserve it and use a new script/take.')
            else: os.replace(work, destination)
            print('Candidate: ' + str(destination / 'narration.json'))
            print('Preview: ' + str(destination / audio.name))
            print('Duration %.2f s, starts at %.2f s. Review sound and phrase timing, then approve.' % (m['duration'], m['offset']))


def approve(args):
    film = Path(args.film).expanduser().resolve()
    candidate = local_path(film, args.take)
    m = json.loads(candidate.read_text())
    script = local_path(film, film / m['script']); audio = local_path(film, film / m['audio'])
    script_data(script)
    checked = manifest(film, candidate.parent, audio, script, m['phrases'], m['source'], m['offset'], m['gain'], m['duckDB'])
    if checked != m: raise ValueError('Candidate audio, script or metadata changed; prepare a new take.')
    if m['offset'] + m['duration'] > args.duration: raise ValueError('Take runs past the film; revise script or film duration.')
    target = film / 'assets/voice/narration.json'
    with lock(target.parent / '.prepare.lock'):
        atomic(target, json_bytes(m))
        atomic(target.with_suffix('.json.approved'), (digest(target) + '\n').encode())
    print('Approved: ' + str(target))
    print('Enable with Film(..., narration: "assets/voice/narration.json"). Rendering uses this saved take only.')


def revise(args):
    film = Path(args.film).expanduser().resolve()
    candidate = local_path(film, args.take)
    m = json.loads(candidate.read_text())
    audio = local_path(film, film / m['audio']); script = local_path(film, film / m['script'])
    if digest(audio) != m['audioSHA256'] or digest(script) != m['scriptSHA256']:
        raise ValueError('Source audio or script changed; prepare a new take.')
    m = manifest(film, candidate.parent, audio, script, m['phrases'], m['source'],
                 m['offset'] if args.offset is None else args.offset,
                 m['gain'] if args.gain is None else args.gain,
                 m['duckDB'] if args.duck_db is None else args.duck_db)
    identity = hashlib.sha256(json_bytes(m)).hexdigest()[:24]
    target = film / 'assets/voice/takes' / identity / 'narration.json'
    with lock(film / 'assets/voice/.prepare.lock'):
        atomic(target, json_bytes(m))
    print('Revised candidate (same audio): ' + str(target))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('status', help='Read-only availability and setup information')
    p = sub.add_parser('setup', help='Download and build optional Kokoro helper once')
    p.add_argument('--asset-source', help='Reuse matching verified download files from this directory')
    for command in ('generate', 'import'):
        p = sub.add_parser(command, help='Prepare a candidate; never approves automatically')
        p.add_argument('film'); p.add_argument('script', help='JSON script inside the film')
        if command == 'import': p.add_argument('audio')
        p.add_argument('--offset', type=float, default=0)
        p.add_argument('--gain', type=float, default=1)
        p.add_argument('--duck-db', type=float, default=8)
    p = sub.add_parser('revise', help='Revise placement/mix without regenerating speech')
    p.add_argument('film'); p.add_argument('take')
    p.add_argument('--offset', type=float); p.add_argument('--gain', type=float); p.add_argument('--duck-db', type=float)
    p = sub.add_parser('approve', help='Record the user-approved take and timing')
    p.add_argument('film'); p.add_argument('take'); p.add_argument('--duration', required=True, type=float)
    args = parser.parse_args()
    if args.command == 'status':
        ready = installed()
        print('Kokoro ready: ' + str(ready) if ready else 'Kokoro not installed for this helper version.')
        print('Optional local English voice: af_heart. Setup downloads about 153 MB; allow 1 GB free for setup.')
        print('Requires Apple Silicon, macOS 15+, command line tools and Python 3 (standard library only).')
        print('No account or STT. Script/audio stays local. Shared cache: ' + str(CACHE))
    elif args.command == 'setup': setup(args)
    elif args.command in ('generate', 'import'): prepare(args)
    elif args.command == 'revise': revise(args)
    else:
        if not math.isfinite(args.duration) or args.duration <= 0: raise ValueError('Film duration must be positive and finite.')
        approve(args)


if __name__ == '__main__':
    try: main()
    except (ValueError, OSError, subprocess.CalledProcessError, KeyError, TypeError) as e:
        print('voice: ' + str(e), file=sys.stderr); sys.exit(1)
