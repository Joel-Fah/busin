"""Writes the scanner's sounds (assets/sounds/*.wav). Original, made from plain tones, so there is nothing to license.

Run from apps/ops:  python3 tool/make_sounds.py
Standard library only. Each sound is short, 22.05 kHz mono 16-bit, a few KB.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, ms, volume=0.6, harmonics=((1, 1.0), (2, 0.25), (3, 0.08)), decay=6.0, attack_ms=4, shape="sine"):
    """A note with a quick attack and an exponential fade, built from a few harmonics."""
    n = int(RATE * ms / 1000)
    attack = max(1, int(RATE * attack_ms / 1000))
    total = sum(weight for _, weight in harmonics)
    samples = []
    for i in range(n):
        t = i / RATE
        value = 0.0
        for multiple, weight in harmonics:
            phase = 2 * math.pi * freq * multiple * t
            if shape == "square":
                wave_value = math.copysign(1.0, math.sin(phase)) * 0.6 + math.sin(phase) * 0.4
            else:
                wave_value = math.sin(phase)
            value += weight * wave_value
        envelope = min(1.0, i / attack) * math.exp(-decay * i / n)
        # A short fade at the very end so no sound ends on a click.
        tail = min(1.0, (n - i) / (RATE * 0.004))
        samples.append(volume * envelope * tail * value / total)
    return samples


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.95 / peak)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))


def overlap(first, second, offset_ms):
    """Plays the second sound offset_ms after the first starts, letting the first ring on underneath."""
    start = int(RATE * offset_ms / 1000)
    out = first + [0.0] * max(0, start + len(second) - len(first))
    for i, s in enumerate(second):
        out[start + i] += s
    return out


def main():
    bell = ((1, 1.0), (2, 0.35), (3, 0.12), (4, 0.05))
    # Let on: two bright rising notes, the second ringing longer.
    write("admit", overlap(tone(880, 160, decay=5, harmonics=bell), tone(1318.5, 320, decay=4.5, harmonics=bell), 95))
    # Already on board: one soft, short note. Nothing to do, just a nod.
    write("again", tone(987.8, 180, volume=0.4, decay=6, harmonics=bell))
    # Refused (no subscription, account not active): two falling low notes.
    low = ((1, 1.0), (3, 0.2), (5, 0.06))
    write("refused", tone(329.6, 150, decay=3, harmonics=low, shape="square") + silence(30) + tone(261.6, 260, decay=3.5, harmonics=low, shape="square"))
    # Suspect code (fake, tampered or an old screenshot): a short harsh triple buzz.
    buzz = ((1, 1.0), (2, 0.5), (3, 0.35), (4, 0.2))
    pulse = tone(196, 85, volume=0.75, decay=1.5, harmonics=buzz, shape="square", attack_ms=2)
    write("suspect", pulse + silence(45) + pulse + silence(45) + pulse)
    # Could not check (no list and no connection): a neutral low blip.
    write("error", tone(440, 140, volume=0.45, decay=5, harmonics=((1, 1.0), (2, 0.1))) + silence(40) + tone(440, 140, volume=0.45, decay=5, harmonics=((1, 1.0), (2, 0.1))))


if __name__ == "__main__":
    main()
