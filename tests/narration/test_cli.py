"""Exercise import, review, revision, failure preservation and cache behavior without a model."""
import array
import importlib.util
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from types import SimpleNamespace
import wave

ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / 'tools/voice/voice.py'
spec = importlib.util.spec_from_file_location('voice', TOOL)
voice = importlib.util.module_from_spec(spec); spec.loader.exec_module(voice)


class VoiceCLI(unittest.TestCase):
    def command(self, *args, success=True):
        result = subprocess.run([sys.executable, str(TOOL), *map(str, args)], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_import_and_revision(self):
        with tempfile.TemporaryDirectory(prefix='voice test ') as temp:
            film = Path(temp); (film / 'scenes').mkdir(); (film / 'assets/voice').mkdir(parents=True)
            script = film / 'assets/voice/script.json'
            script.write_text(json.dumps({'phrases': [{'id': 'one', 'text': 'Hello there.', 'start': 0, 'end': 1}]}))
            audio = film / 'original take.wav'
            with wave.open(str(audio), 'wb') as f:
                f.setnchannels(1); f.setsampwidth(2); f.setframerate(24000)
                f.writeframes(array.array('h', [int(3000 * math.sin(i * 0.05)) for i in range(24000)]).tobytes())
            original = voice.digest(audio)
            self.command('import', film, script, audio, '--offset', '0.2')
            candidate = next((film / 'assets/voice/takes').glob('*/narration.json'))
            self.assertFalse((film / 'assets/voice/narration.json').exists())
            self.command('approve', film, candidate, '--duration', '0.5', success=False)
            self.command('approve', film, candidate, '--duration', '3')
            approved = film / 'assets/voice/narration.json'; before = approved.read_bytes()
            self.command('revise', film, candidate, '--gain', '0.5', '--offset', '1')
            self.assertEqual(before, approved.read_bytes(), 'revision must not auto-approve')
            revised = [p for p in (film / 'assets/voice/takes').glob('*/narration.json') if p != candidate][0]
            self.command('approve', film, revised, '--duration', '3')
            self.assertEqual(json.loads(approved.read_text())['offset'], 1)
            before = approved.read_bytes()
            self.command('import', film, script, audio, '--gain', 'nan', success=False)
            self.assertEqual(before, approved.read_bytes(), 'failed import preserves prior approved take')
            self.assertEqual(original, voice.digest(audio), 'import must preserve source')
            corrupt = film / 'corrupt.wav'; corrupt.write_bytes(b'not audio')
            result = self.command('import', film, script, corrupt, success=False)
            self.assertNotIn('Fatal error', result.stderr)
            self.assertEqual(before, approved.read_bytes(), 'corrupt source preserves prior approval')
            self.assertFalse(any(p.name.startswith('.take-') for p in (film / 'assets/voice/takes').iterdir()))
            # An editor saving while decoding must not attach new words to old audio.
            original_script = script.read_bytes()
            def edit_during_decode(_):
                script.write_text(json.dumps({'phrases': [{'id': 'new', 'text': 'New words.'}]}))
                return {'duration': 1, 'peak': 0.1}
            args = SimpleNamespace(command='import', film=str(film), script=str(script), audio=str(audio),
                                   offset=0, gain=1, duck_db=8)
            try:
                with mock.patch.object(voice, 'audio_info', side_effect=edit_during_decode):
                    with self.assertRaisesRegex(ValueError, 'Script changed during preparation'):
                        voice.prepare(args)
            finally:
                script.write_bytes(original_script)
            self.assertEqual(before, approved.read_bytes())
            self.assertFalse(any(p.name.startswith('.take-') for p in (film / 'assets/voice/takes').iterdir()))
            # Caption text for an existing recording need not be TTS-ready spoken words.
            numeric_script = film / 'assets/voice/price.json'
            numeric_script.write_text(json.dumps({'phrases': [{'id': 'price', 'text': '$9.99', 'start': 0, 'end': 1}]}))
            self.command('import', film, numeric_script, audio)
            # A hand-edited candidate must fail during approval, not only in the renderer.
            broken = json.loads(candidate.read_text())
            broken['phrases'] *= 2
            invalid = film / 'assets/voice/invalid.json'; invalid.write_text(json.dumps(broken))
            self.command('approve', film, invalid, '--duration', '3', success=False)
            self.assertEqual(before, approved.read_bytes())
            script.write_text(script.read_text().replace('Hello there.', 'Changed words.'))
            self.command('approve', film, candidate, '--duration', '3', success=False)
            self.command('generate', film, script, success=False)  # no model: fail without downloading
            self.assertFalse((voice.CACHE / 'downloads').exists())

    def test_validation(self):
        with tempfile.TemporaryDirectory() as temp:
            script = Path(temp) / 'script.json'
            for data in ([], {'phrases': ['wrong type']}, {'phrases': []}, {'phrases': [{'id': 'a', 'text': ''}]},
                         {'phrases': [{'id': 'a', 'text': 'Hello', 'pauseAfter': -1}]},
                         {'phrases': [{'id': 'a', 'text': 'Hi'}, {'id': 'a', 'text': 'Bye'}]}):
                script.write_text(json.dumps(data))
                with self.assertRaises(ValueError): voice.script_data(script)
            with self.assertRaises(ValueError): voice.local_path(Path(temp), '/etc/hosts')

    def test_status_has_no_setup_side_effect(self):
        with tempfile.TemporaryDirectory() as temp:
            cache = Path(temp) / 'not-created'
            result = subprocess.run([sys.executable, str(TOOL), 'status'], env={**os.environ, 'MOTIONABLE_VOICE_CACHE': str(cache)}, capture_output=True)
            self.assertEqual(result.returncode, 0)
            self.assertFalse(cache.exists())


if __name__ == '__main__': unittest.main()
