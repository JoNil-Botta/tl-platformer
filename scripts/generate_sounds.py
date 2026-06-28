#!/usr/bin/env python3
"""Generate simple 8-bit mono WAV sound effects for tl-platformer."""

import struct
import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "assets", "sounds")
SAMPLE_RATE = 22050

def write_wav(filename, samples):
    """Write 8-bit unsigned mono WAV."""
    data = bytes(int((s + 1.0) * 127.5) & 0xFF for s in samples)
    with open(filename, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(data)))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))  # chunk size
        f.write(struct.pack("<H", 1))   # PCM
        f.write(struct.pack("<H", 1))   # mono
        f.write(struct.pack("<I", SAMPLE_RATE))
        f.write(struct.pack("<I", SAMPLE_RATE))  # byte rate
        f.write(struct.pack("<H", 1))   # block align
        f.write(struct.pack("<H", 8))   # bits per sample
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", len(data)))
        f.write(data)

def square_wave(freq, duration, duty=0.5):
    """Generate square wave samples."""
    samples = []
    period = SAMPLE_RATE / freq
    for i in range(int(SAMPLE_RATE * duration)):
        phase = (i % period) / period
        samples.append(1.0 if phase < duty else -1.0)
    return samples

def sine_wave(freq, duration):
    """Generate sine wave samples."""
    samples = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        samples.append(math.sin(2 * math.pi * freq * t))
    return samples

def noise(duration):
    """Generate white noise samples."""
    import random
    samples = []
    for _ in range(int(SAMPLE_RATE * duration)):
        samples.append(random.uniform(-1.0, 1.0))
    return samples

def fade_out(samples, fade_start=0.3):
    """Apply fade-out envelope."""
    total = len(samples)
    fade_start_idx = int(total * fade_start)
    for i in range(fade_start_idx, total):
        samples[i] *= (total - i) / (total - fade_start_idx)
    return samples

def arpeggio(freqs, duration_per_note, total_duration):
    """Play a sequence of frequencies."""
    samples = []
    samples_per_note = int(SAMPLE_RATE * duration_per_note)
    for freq in freqs:
        note = square_wave(freq, duration_per_note)
        note = fade_out(note, fade_start=0.5)
        samples.extend(note)
    # Trim or pad to total_duration
    target = int(SAMPLE_RATE * total_duration)
    if len(samples) < target:
        samples.extend([0.0] * (target - len(samples)))
    else:
        samples = samples[:target]
    return samples

def slide(freq_start, freq_end, duration):
    """Frequency slide."""
    samples = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        frac = t / duration
        freq = freq_start + (freq_end - freq_start) * frac
        phase = (i * freq / SAMPLE_RATE) % 1.0
        samples.append(1.0 if phase < 0.5 else -1.0)
    return fade_out(samples, fade_start=0.2)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # Jump: rising slide
    jump = slide(300, 600, 0.15)
    write_wav(os.path.join(OUT_DIR, "jump.wav"), jump)

    # Coin: high ping
    coin = square_wave(1200, 0.1)
    coin = fade_out(coin, fade_start=0.0)
    write_wav(os.path.join(OUT_DIR, "coin.wav"), coin)

    # Stomp: low thud
    stomp = square_wave(150, 0.15)
    stomp = fade_out(stomp, fade_start=0.1)
    write_wav(os.path.join(OUT_DIR, "stomp.wav"), stomp)

    # Death: descending slide
    death = slide(500, 100, 0.4)
    write_wav(os.path.join(OUT_DIR, "death.wav"), death)

    # Power-up: ascending arpeggio
    powerup = arpeggio([440, 554, 659, 880], 0.08, 0.4)
    write_wav(os.path.join(OUT_DIR, "powerup.wav"), powerup)

    # 1-UP: cheerful high arpeggio
    oneup = arpeggio([880, 1109, 1318, 1760], 0.06, 0.3)
    write_wav(os.path.join(OUT_DIR, "oneup.wav"), oneup)

    # Bump (hit block from below): short dull thud
    bump = square_wave(200, 0.08)
    bump = fade_out(bump, fade_start=0.0)
    write_wav(os.path.join(OUT_DIR, "bump.wav"), bump)

    print(f"Generated {len(os.listdir(OUT_DIR))} sound files in {OUT_DIR}")

if __name__ == "__main__":
    main()
