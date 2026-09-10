#!/usr/bin/env python3
"""Generate the original Tash Rush sound pack using procedural synthesis."""

from __future__ import annotations

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
RNG = random.Random(20260910)


def silence(seconds: float) -> list[float]:
    return [0.0] * int(seconds * SAMPLE_RATE)


def mix(target: list[float], source: list[float], start: float = 0.0, gain: float = 1.0) -> None:
    offset = int(start * SAMPLE_RATE)
    needed = offset + len(source)
    if needed > len(target):
        target.extend([0.0] * (needed - len(target)))
    for index, sample in enumerate(source):
        target[offset + index] += sample * gain


def envelope(position: float, duration: float, attack: float, release: float) -> float:
    if position < attack:
        return position / max(attack, 1e-6)
    remaining = duration - position
    return max(0.0, remaining / max(release, 1e-6)) if remaining < release else 1.0


def tone(frequency: float, duration: float, *, gain: float = 1.0,
         attack: float = 0.005, release: float = 0.08,
         end_frequency: float | None = None,
         harmonics: tuple[tuple[int, float], ...] = ((1, 1.0),)) -> list[float]:
    result = silence(duration)
    phase = 0.0
    for index in range(len(result)):
        time = index / SAMPLE_RATE
        progress = time / duration
        current = frequency if end_frequency is None else frequency * ((end_frequency / frequency) ** progress)
        phase += 2.0 * math.pi * current / SAMPLE_RATE
        value = sum(math.sin(phase * multiplier) * level for multiplier, level in harmonics)
        result[index] = value * gain * envelope(time, duration, attack, release)
    return result


def pluck(frequency: float, duration: float, *, gain: float = 1.0,
          brightness: float = 0.992) -> list[float]:
    delay = max(2, round(SAMPLE_RATE / frequency))
    ring = [RNG.uniform(-1.0, 1.0) for _ in range(delay)]
    result = silence(duration)
    for index in range(len(result)):
        current = ring[index % delay]
        following = ring[(index + 1) % delay]
        ring[index % delay] = brightness * 0.5 * (current + following)
        time = index / SAMPLE_RATE
        body = 0.12 * math.sin(2.0 * math.pi * frequency * time)
        result[index] = (current + body) * gain * envelope(time, duration, 0.002, min(0.16, duration * 0.4))
    return result


def noise_burst(duration: float, *, gain: float = 1.0, decay: float = 8.0) -> list[float]:
    result = silence(duration)
    previous = 0.0
    for index in range(len(result)):
        time = index / SAMPLE_RATE
        previous = previous * 0.70 + RNG.uniform(-1.0, 1.0) * 0.30
        result[index] = previous * math.exp(-decay * time) * gain
    return result


def normalize(samples: list[float], peak: float = 0.9) -> list[float]:
    maximum = max((abs(value) for value in samples), default=1.0)
    scale = peak / maximum if maximum > peak else 1.0
    return [math.tanh(value * scale * 1.08) / math.tanh(1.08) for value in samples]


def write_mp3(name: str, samples: list[float], *, music: bool = False) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    samples = normalize(samples, 0.86 if music else 0.92)
    delay = int(SAMPLE_RATE * 0.006)
    width = 0.22 if music else 0.10
    right = [value * (1.0 - width) + (samples[index - delay] if index >= delay else 0.0) * width
             for index, value in enumerate(samples)]
    with tempfile.TemporaryDirectory(prefix="tash_rush_audio_") as temp_dir:
        wav_path = Path(temp_dir) / f"{name}.wav"
        with wave.open(str(wav_path), "wb") as wav_file:
            wav_file.setparams((2, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
            frames = bytearray()
            for left, right_sample in zip(samples, right):
                frames.extend(struct.pack("<hh", int(max(-1, min(1, left)) * 32767),
                                          int(max(-1, min(1, right_sample)) * 32767)))
            wav_file.writeframes(frames)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                        "-i", str(wav_path), "-codec:a", "libmp3lame", "-b:a",
                        "160k" if music else "128k", str(OUTPUT / f"{name}.mp3")], check=True)


def make_place() -> list[float]:
    out = silence(0.30)
    mix(out, pluck(220.0, 0.24, gain=0.72))
    mix(out, tone(110.0, 0.12, gain=0.30, end_frequency=78.0, release=0.09))
    mix(out, noise_burst(0.055, gain=0.18, decay=35.0))
    return out


def make_clear() -> list[float]:
    out = silence(0.72)
    for start, note in zip((0.0, 0.09, 0.18, 0.27), (293.66, 392.0, 440.0, 587.33)):
        mix(out, pluck(note, 0.38, gain=0.55), start)
    mix(out, tone(700.0, 0.42, gain=0.18, end_frequency=1450.0, release=0.20), 0.08)
    return out


def make_combo() -> list[float]:
    out = silence(0.82)
    for start, note in zip((0.0, 0.12, 0.24, 0.36), (392.0, 440.0, 587.33, 783.99)):
        mix(out, pluck(note, 0.42, gain=0.58, brightness=0.994), start)
    mix(out, tone(1174.66, 0.32, gain=0.20, release=0.25), 0.40)
    return out


def make_explosion() -> list[float]:
    out = silence(1.20)
    mix(out, noise_burst(1.05, gain=1.05, decay=4.0))
    mix(out, tone(105.0, 0.92, gain=0.88, end_frequency=34.0, attack=0.001, release=0.38))
    mix(out, tone(54.0, 0.72, gain=0.52, end_frequency=29.0, attack=0.001, release=0.30), 0.05)
    for start in (0.0, 0.035, 0.075):
        mix(out, noise_burst(0.16, gain=0.50, decay=18.0), start)
    return out


def make_gold() -> list[float]:
    out = silence(0.92)
    for start, note in zip((0.0, 0.07, 0.15, 0.25), (880.0, 1174.66, 1396.91, 1760.0)):
        mix(out, tone(note, 0.44, gain=0.24, release=0.30,
                      harmonics=((1, 1.0), (2, 0.25), (3, 0.08))), start)
    return out


def make_game_over() -> list[float]:
    out = silence(1.65)
    for start, note in zip((0.0, 0.28, 0.56, 0.84), (440.0, 392.0, 293.66, 220.0)):
        mix(out, pluck(note, 0.62, gain=0.52, brightness=0.990), start)
    mix(out, tone(110.0, 0.70, gain=0.25, end_frequency=73.42, release=0.40), 0.82)
    return out


def make_button() -> list[float]:
    out = silence(0.18)
    mix(out, pluck(587.33, 0.14, gain=0.38, brightness=0.988))
    mix(out, tone(880.0, 0.10, gain=0.14, release=0.07), 0.018)
    return out


def make_achievement() -> list[float]:
    out = silence(1.45)
    for index, note in enumerate((293.66, 392.0, 440.0, 587.33, 783.99)):
        mix(out, pluck(note, 0.62, gain=0.46, brightness=0.994), index * 0.13)
    for note in (587.33, 739.99, 880.0):
        mix(out, tone(note, 0.62, gain=0.13, release=0.46), 0.68)
    return out


def make_music() -> list[float]:
    beat = 0.60
    out = silence(8 * 4 * beat)
    melody = (293.66, 392.0, 440.0, 392.0, 293.66, 261.63, 293.66, 392.0,
              440.0, 523.25, 440.0, 392.0, 293.66, 392.0, 261.63, 293.66,
              392.0, 440.0, 587.33, 440.0, 392.0, 293.66, 261.63, 293.66,
              440.0, 392.0, 293.66, 261.63, 220.0, 261.63, 293.66, 293.66)
    roots = (146.83, 130.81, 110.0, 146.83, 130.81, 146.83, 110.0, 146.83)
    for index, note in enumerate(melody):
        mix(out, pluck(note, beat * 0.86, gain=0.24, brightness=0.995), index * beat)
        if index % 2:
            mix(out, pluck(note * 2.0, beat * 0.34, gain=0.08, brightness=0.991),
                index * beat + beat * 0.48)
    for bar, root in enumerate(roots):
        start = bar * 4 * beat
        mix(out, pluck(root, beat * 1.75, gain=0.24, brightness=0.996), start)
        mix(out, pluck(root * 1.5, beat * 1.55, gain=0.16, brightness=0.995), start + 2 * beat)
        for pulse in range(4):
            mix(out, noise_burst(0.075, gain=0.045, decay=38.0), start + pulse * beat)
    fade = int(0.025 * SAMPLE_RATE)
    for index in range(fade):
        amount = index / fade
        out[index] *= amount
        out[-index - 1] *= amount
    return out


def main() -> None:
    sounds = {"place": make_place(), "clear": make_clear(), "combo": make_combo(),
              "explosion": make_explosion(), "gold": make_gold(),
              "game_over": make_game_over(), "button": make_button(),
              "achievement": make_achievement(), "music": make_music()}
    for name, samples in sounds.items():
        write_mp3(name, samples, music=name == "music")
        print(f"generated {name}.mp3")


if __name__ == "__main__":
    main()
