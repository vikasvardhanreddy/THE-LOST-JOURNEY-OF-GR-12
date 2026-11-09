"""Generate original, lightweight PCM audio assets for THE LOST JOURNEY OF GR.

Uses only Python's standard library. The resulting mono WAVs are loopable and
compressed by Godot during import for Android exports.
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
RATE = 22050


def envelope(t, duration, attack=0.08, release=0.15):
    return min(1.0, t / max(attack, 0.001), (duration - t) / max(release, 0.001))


def write_wav(path, samples, loop=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max((abs(x) for x in samples), default=1.0) or 1.0
    scale = min(0.92 / peak, 1.0)
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * scale)) * 32767)) for x in samples))


def make_music(filename, chords, mood=0):
    duration = 12.0
    total = int(RATE * duration)
    samples = []
    chord_len = duration / len(chords)
    for i in range(total):
        t = i / RATE
        chord = chords[int(t / chord_len) % len(chords)]
        local = (t % chord_len) / chord_len
        fade = min(1.0, (1.0 - local) * 7.0, local * 7.0 + 0.2)
        # Three soft detuned partials per chord form a warm evolving pad.
        value = 0.0
        for n, freq in enumerate(chord):
            phase = 2 * math.pi * freq * t
            vibrato = math.sin(2 * math.pi * (0.07 + n * 0.012) * t) * 0.003
            value += math.sin(phase + vibrato) * (0.12 / (n + 1))
            value += math.sin(phase * 2.003) * (0.025 / (n + 1))
        # Gentle low movement and a slow, loop-safe shimmer.
        value += math.sin(2 * math.pi * (chord[0] / 2) * t) * 0.055
        value += math.sin(2 * math.pi * (chord[-1] * 2) * t) * (0.018 + mood * 0.002) * (0.5 + 0.5 * math.sin(2 * math.pi * t / duration))
        samples.append(value * (0.65 + fade * 0.35))
    write_wav(os.path.join(ROOT, "music", filename), samples, True)


def make_tone(filename, notes, duration, waveform="sine", noise=0.0):
    rng = random.Random(filename)
    samples = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        value = 0.0
        for freq, start, length, amp in notes:
            local = t - start
            if 0 <= local <= length:
                e = envelope(local, length, min(0.025, length * 0.3), min(0.16, length * 0.45))
                phase = 2 * math.pi * freq * local
                tone = math.sin(phase) if waveform == "sine" else math.sin(phase) * 0.75 + math.sin(phase * 2) * 0.2
                value += tone * e * amp
        if noise:
            value += (rng.random() * 2 - 1) * noise * math.exp(-t * 11)
        samples.append(value)
    write_wav(os.path.join(ROOT, "sfx", filename), samples)


def main():
    # Original, mellow chord beds. Frequencies are generated here, not sampled.
    make_music("chapter_01_forest.wav", [[146.83, 220, 293.66], [130.81, 196, 261.63], [174.61, 220, 261.63], [146.83, 196, 246.94]])
    make_music("chapter_02_village.wav", [[110, 164.81, 220], [98, 146.83, 196], [130.81, 164.81, 196], [110, 146.83, 174.61]], 1)
    make_music("chapter_03_cave.wav", [[73.42, 110, 146.83], [82.41, 123.47, 164.81], [65.41, 98, 130.81], [73.42, 110, 146.83]], 2)
    make_music("chapter_04_laboratory.wav", [[123.47, 185, 246.94], [110, 164.81, 220], [138.59, 185, 220], [123.47, 164.81, 207.65]], 3)
    make_music("chapter_05_truth.wav", [[146.83, 220, 293.66], [164.81, 246.94, 329.63], [130.81, 196, 261.63], [146.83, 220, 293.66]], 4)
    make_music("menu_theme.wav", [[130.81, 196, 261.63], [146.83, 220, 293.66], [110, 164.81, 220], [130.81, 196, 261.63]])
    make_tone("footstep.wav", [(98, 0, 0.12, 0.8), (65, 0.015, 0.10, 0.35)], 0.17, "sine", 0.18)
    make_tone("button_click.wav", [(920, 0, 0.045, 0.55), (620, 0.018, 0.06, 0.38)], 0.09)
    make_tone("item_pickup.wav", [(660, 0, 0.12, 0.5), (880, 0.07, 0.16, 0.48), (1320, 0.17, 0.24, 0.38)], 0.44)
    make_tone("puzzle_complete.wav", [(523.25, 0, 0.22, 0.34), (659.25, 0.1, 0.24, 0.38), (783.99, 0.2, 0.42, 0.45)], 0.68)
    make_tone("door.wav", [(180, 0, 0.32, 0.46), (118, 0.2, 0.45, 0.5), (73, 0.48, 0.3, 0.3)], 0.82, "sine", 0.06)
    make_tone("interaction.wav", [(480, 0, 0.07, 0.25), (720, 0.035, 0.09, 0.22)], 0.15)


if __name__ == "__main__":
    main()
