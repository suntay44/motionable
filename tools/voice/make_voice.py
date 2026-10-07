"""One Kokoro voice as raw floats: python3 make_voice.py <voices-v1.0.bin> <voice> <out.bin>

voices-v1.0.bin is a NumPy .npz archive with one (510, 1, 256) float32 array per voice: one style
vector for each phoneme count. The app reads the chosen voice's 510 x 256 little-endian floats."""
import ast
import struct
import sys
import zipfile

ROWS, WIDTH = 510, 256


def voice_floats(archive_path, voice):
    with zipfile.ZipFile(archive_path) as archive:
        data = archive.read(voice + ".npy")
    assert data[:6] == b"\x93NUMPY", "not a .npy array"
    major = data[6]
    if major == 1:
        (header_length,), start = struct.unpack("<H", data[8:10]), 10
    else:
        (header_length,), start = struct.unpack("<I", data[8:12]), 12
    header = ast.literal_eval(data[start:start + header_length].decode("latin1"))
    assert header["descr"] == "<f4" and not header["fortran_order"], header
    assert tuple(header["shape"]) == (ROWS, 1, WIDTH), header["shape"]
    body = data[start + header_length:]
    assert len(body) == ROWS * WIDTH * 4
    return body


if __name__ == "__main__":
    archive_path, voice, target = sys.argv[1:4]
    body = voice_floats(archive_path, voice)
    with open(target, "wb") as file:
        file.write(body)
    print(f"{voice}: {ROWS} x {WIDTH} floats -> {target}")
