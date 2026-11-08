#!/usr/bin/env python3
"""Gera as músicas (rock sintetizado: guitarra, baixo, bateria) e os efeitos do FMF.

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


# ------------------------------------------------------------- instrumentos de rock
def saw(freq, t):
    return 2.0 * ((t * freq) % 1.0) - 1.0


def guitar(freq, vol, a=0.004, r=0.05, gain=4.0, muted=False):
    """Guitarra base: power chord (fundamental + quinta + oitava) com distorção."""
    def fn(t, i, n):
        x = saw(freq, t) + 0.8 * saw(freq * 1.4983, t) + 0.6 * saw(freq * 2.0, t)
        x += 0.3 * square(freq * 0.5, t)
        e = env(i, n, a, r)
        if muted:  # palm mute: decai rápido
            e *= math.exp(-t * 22.0)
        return vol * e * math.tanh(gain * x * 0.4)
    return fn


def lead_guitar(freq, vol, a=0.01, r=0.07):
    """Guitarra solo: serra + quadrada, vibrato suave e distorção."""
    def fn(t, i, n):
        depth = 0.010 * min(1.0, t / 0.25)  # vibrato entra devagar
        ph = t * freq + (depth * freq / (2 * math.pi * 5.5)) * (1 - math.cos(2 * math.pi * 5.5 * t))
        x = 2.0 * (ph % 1.0) - 1.0
        x = 0.7 * x + 0.5 * (1.0 if (ph % 1.0) < 0.35 else -1.0)
        return vol * env(i, n, a, r) * math.tanh(2.2 * x)
    return fn


def bass_guitar(freq, vol, r=0.04):
    def fn(t, i, n):
        x = triangle(freq, t) + 0.5 * saw(freq, t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
        return vol * env(i, n, 0.003, r) * math.tanh(1.6 * x * 0.6) * math.exp(-t * 3.0)
    return fn


def snare(vol):
    rng = random.Random(7)
    def fn(t, i, n):
        body = math.sin(2 * math.pi * (190 * math.exp(-t * 14) + 130) * t)
        return vol * env(i, n, 0.001, 0.05) * (0.7 * (rng.random() * 2 - 1) + 0.6 * body) * math.exp(-t * 16)
    return fn


def hat(vol, open_=False):
    rng = random.Random(3)
    last = [0.0]
    def fn(t, i, n):
        x = rng.random() * 2 - 1
        y = x - last[0]  # passa-alta
        last[0] = x
        return vol * env(i, n, 0.001, 0.02) * y * math.exp(-t * (14 if open_ else 55))
    return fn


def crash(vol):
    rng = random.Random(11)
    last = [0.0]
    def fn(t, i, n):
        x = rng.random() * 2 - 1
        y = x - last[0]
        last[0] = x
        return vol * env(i, n, 0.001, 0.2) * y * math.exp(-t * 2.6)
    return fn


def tom(vol, f0):
    def fn(t, i, n):
        f = f0 * math.exp(-t * 6) + f0 * 0.6
        return vol * env(i, n, 0.002, 0.06) * math.sin(2 * math.pi * f * t) * math.exp(-t * 7)
    return fn


# ------------------------------------------------------------- faixas
MINOR_A = [(12, 1), (15, .5), (12, .5), (10, 1), (7, 1), (10, 1), (12, 1), (15, 2),
           (17, 1), (15, .5), (12, .5), (10, 1), (7, 1), (5, 1), (7, 1), (0, 2)]
MINOR_B = [(19, .5), (17, .5), (15, 1), (12, 1), (15, 1), (17, 1), (15, 1), (12, 2),
           (19, .5), (17, .5), (15, 1), (12, 1), (10, 1), (12, 2), (7, 2)]
MAJOR_A = [(12, 1), (14, .5), (12, .5), (9, 1), (7, 1), (9, 1), (12, 1), (16, 2),
           (14, 1), (12, .5), (9, .5), (7, 1), (4, 1), (2, 1), (4, 1), (0, 2)]
MAJOR_B = [(19, .5), (16, .5), (14, 1), (12, 1), (14, 1), (16, 1), (14, 1), (12, 2),
           (19, .5), (16, .5), (14, 1), (12, 1), (9, 1), (12, 2), (7, 2)]


def rock_track(out_name, bpm, key, prog, major=False, double_kick=False, swing_lead=0):
    """16 compassos: 4 de riff (intro) + solo A, B, A. key = nota MIDI da tônica
    (grave); prog = 16 deslocamentos em semitons da fundamental de cada compasso."""
    beat = 60 / bpm
    bar = 4 * beat
    la, lb = (MAJOR_A, MAJOR_B) if major else (MINOR_A, MINOR_B)
    ev = []
    for b, off in enumerate(prog):
        t0 = b * bar
        root = key + off
        f_root = midi(root + 12)
        # guitarra base: colcheias com palm mute; acento no 1 e no "e" do 3
        for e in range(8):
            accent = e in (0, 5)
            ev.append((t0 + e * beat / 2, beat / 2 * (0.95 if accent else 0.7),
                       guitar(f_root, 0.55 if accent else 0.42, muted=not accent)))
        # baixo em colcheias
        for e in range(8):
            ev.append((t0 + e * beat / 2, beat / 2 * 0.9, bass_guitar(midi(root), 0.55)))
        # bateria
        for q in range(4):
            ev.append((t0 + q * beat, 0.05, hat(0.18)))
            ev.append((t0 + q * beat + beat / 2, 0.05, hat(0.1)))
        ev.append((t0, 0.14, kick(0.95)))
        ev.append((t0 + 2 * beat, 0.14, kick(0.95)))
        ev.append((t0 + 2.5 * beat, 0.14, kick(0.8)))
        if double_kick and b % 4 == 3:
            for e in range(8):
                ev.append((t0 + e * beat / 2, 0.1, kick(0.7)))
        ev.append((t0 + beat, 0.2, snare(0.85)))
        ev.append((t0 + 3 * beat, 0.2, snare(0.85)))
        if b % 4 == 0:
            ev.append((t0, 0.9, crash(0.5)))
        if b % 4 == 3:  # virada de tambor
            for k, f in enumerate([220, 180, 150]):
                ev.append((t0 + (3 + k * 0.3333) * beat, 0.2, tom(0.7, f)))
    # solo de guitarra nos compassos 4..15
    for start_bar, phrase in ((4, la), (8, lb), (12, la)):
        mt = start_bar * bar
        for step, dur in phrase:
            f = midi(key + 24 + step)
            ev.append((mt, dur * beat * 0.97, lead_guitar(f, 0.38)))
            mt += dur * beat
    render(ev, 16 * bar, out_name, master=0.8)


def world1():
    # Floresta: Mi menor, andamento de corrida
    rock_track("world1.wav", 150, 40,
        [0, 0, 8, 10, 0, 0, 8, 10, 5, 5, 3, 3, 0, 8, 10, 7])


def world2():
    # Ilha: Lá maior, surf-rock animado
    rock_track("world2.wav", 158, 45,
        [0, 0, 5, 7, 0, 0, 5, 7, 9, 9, 5, 7, 0, 5, 7, 0], major=True)


def world3():
    # Montanha gelada: Ré menor, mais pesado
    rock_track("world3.wav", 136, 38,
        [0, 0, 3, 5, 0, 0, 3, 7, 8, 8, 5, 5, 0, 3, 5, 7], double_kick=True)


def world4():
    # Lua: Sol menor, rock espacial rápido
    rock_track("world4.wav", 164, 43,
        [0, 0, 5, 3, 0, 0, 5, 3, 8, 8, 10, 10, 0, 5, 3, 10])


def world5():
    # Montanhas / gorilas: Dó menor, riff pesado
    rock_track("world5.wav", 142, 36,
        [0, 0, 0, 3, 0, 0, 5, 3, 8, 8, 10, 10, 0, 3, 5, 7], double_kick=True)


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
    world2()
    world3()
    world4()
    world5()
    sfx()
    print("audio OK")
