#!/usr/bin/env python3
"""Gera a música do mundo 1 e os efeitos sonoros do FMF (chiptune sintetizado).

Uso: python3 tools/gen_audio.py
Saída em assets/audio/ (WAV 22050 Hz, 16-bit, mono).
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def square(freq, t, duty=0.5):
    return 1.0 if (t * freq) % 1.0 < duty else -1.0


def triangle(freq, t):
    p = (t * freq) % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def env(i, n, a=0.01, r=0.08):
    """Envelope: ataque linear, sustain, release."""
    t = i / SR
    dur = n / SR
    if t < a:
        return t / a
    if t > dur - r:
        return max(0.0, (dur - t) / r)
    return 1.0


def render(events, total, out_name, master=0.9):
    """events: lista de (start_s, dur_s, fn(t_local)->amp)."""
    n = int(total * SR)
    buf = [0.0] * n
    for start, dur, fn in events:
        i0 = int(start * SR)
        ln = int(dur * SR)
        for i in range(ln):
            if i0 + i >= n:
                break
            buf[i0 + i] += fn(i / SR, i, ln)
    peak = max(1e-6, max(abs(v) for v in buf))
    scale = master * 32767 / peak
    data = b"".join(struct.pack("<h", int(v * scale)) for v in buf)
    with wave.open(os.path.join(OUT, out_name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(out_name, f"{total:.2f}s")


def tone(freq, vol, wave_fn=square, duty=0.5, a=0.01, r=0.08):
    if wave_fn is square:
        return lambda t, i, n: vol * env(i, n, a, r) * square(freq, t, duty)
    return lambda t, i, n: vol * env(i, n, a, r) * wave_fn(freq, t)


def sweep(f0, f1, vol, a=0.005, r=0.05):
    def fn(t, i, n):
        dur = n / SR
        f = f0 + (f1 - f0) * (t / dur)
        return vol * env(i, n, a, r) * square(f, t)
    return fn


def noise_hit(vol, r=0.04):
    rng = random.Random(1)
    def fn(t, i, n):
        return vol * env(i, n, 0.002, r) * (rng.random() * 2 - 1)
    return fn


def kick(vol):
    def fn(t, i, n):
        f = 120 * math.exp(-t * 18) + 45
        return vol * env(i, n, 0.002, 0.05) * math.sin(2 * math.pi * f * t)
    return fn


# ------------------------------------------------------------- música
def world1():
    bpm = 112
    beat = 60 / bpm
    bar = 4 * beat
    # acordes: (fundamental midi, [graus do arpejo])
    AM, F, C, G = 57, 53, 48, 55
    prog = [
        (AM, [0, 3, 7]),   # Am
        (F, [0, 4, 7]),    # F
        (C, [0, 4, 7]),    # C
        (G, [0, 4, 7]),    # G
        (AM, [0, 3, 7]),
        (F, [0, 4, 7]),
        (C, [0, 4, 7]),
        (G, [0, 4, 7]),
    ]
    melody = [  # (midi, dur em beats) por compasso
        [(69, 1.5), (71, 0.5), (72, 1), (76, 1)],
        [(77, 2), (76, 1), (72, 1)],
        [(67, 1.5), (69, 0.5), (71, 1), (72, 1)],
        [(74, 3), (71, 1)],
        [(69, 1.5), (72, 0.5), (76, 1), (81, 1)],
        [(79, 2), (77, 1), (76, 1)],
        [(76, 1.5), (74, 0.5), (72, 1), (74, 1)],
        [(71, 2), (67, 2)],
    ]
    ev = []
    for b, (root, degrees) in enumerate(prog):
        t0 = b * bar
        # baixo: colcheias fundamental/quinta
        for e in range(8):
            note = root - 12 + (7 if e in (2, 6) else 0)
            ev.append((t0 + e * beat / 2, beat / 2 * 0.9,
                       tone(midi(note), 0.55, triangle)))
        # arpejo: semicolcheias
        for sxt in range(16):
            deg = degrees[sxt % len(degrees)]
            ev.append((t0 + sxt * beat / 4, beat / 4 * 0.8,
                       tone(midi(root + 12 + deg), 0.18, square, 0.25, 0.002, 0.02)))
        # percussão
        for e in range(8):
            ev.append((t0 + e * beat / 2, 0.03, noise_hit(0.22 if e % 2 == 0 else 0.12)))
        ev.append((t0, 0.12, kick(0.8)))
        ev.append((t0 + 2 * beat, 0.12, kick(0.8)))
        # melodia
        mt = t0
        for note, dur in melody[b]:
            ev.append((mt, dur * beat * 0.95, tone(midi(note), 0.5, square, 0.5, 0.01, 0.06)))
            mt += dur * beat
    render(ev, 8 * bar, "world1.wav", master=0.75)


def sfx():
    render([(0, 0.06, noise_hit(0.8)), (0, 0.10, sweep(500, 220, 0.6))], 0.12, "hit.wav")
    render([(0, 0.22, sweep(320, 70, 0.8))], 0.25, "hurt.wav")
    render([(0, 0.06, tone(988, 0.7, square, 0.5, 0.002, 0.01)),
            (0.06, 0.14, tone(1319, 0.7, square, 0.5, 0.002, 0.06))], 0.2, "coin.wav")
    render([(0, 0.14, sweep(180, 520, 0.6))], 0.15, "jump.wav")
    render([(i * 0.09, 0.12, tone(midi(n), 0.7, square, 0.4, 0.004, 0.04))
            for i, n in enumerate([69, 72, 76, 81])], 0.5, "levelup.wav")
    render([(i * 0.16, d, tone(midi(n), 0.7, square, 0.5, 0.004, 0.06))
            for i, (n, d) in enumerate([(72, 0.14), (72, 0.14), (72, 0.14),
                                        (76, 0.3), (79, 0.5)])], 1.3, "victory.wav")
    render([(0, 0.3, sweep(140, 60, 0.9)), (0, 0.12, noise_hit(0.5, 0.1))], 0.35, "boss_roar.wav")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    world1()
    sfx()
    print("audio OK")
