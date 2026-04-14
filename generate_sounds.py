#!/usr/bin/env python3
"""
Sound effect generator for HorseShooter game
Creates retro/8-bit style sound effects procedurally
"""

import wave
import struct
import math
import os


def create_directory():
    """Create sounds directory if it doesn't exist"""
    os.makedirs("/home/rowan/horseshooter/HorseShooter/assets/sounds", exist_ok=True)


def generate_wave(filename, samples, sample_rate=22050):
    """Write samples to a WAV file"""
    with wave.open(filename, "w") as wav:
        wav.setnchannels(1)  # Mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(sample_rate)

        for sample in samples:
            # Clamp sample to 16-bit range
            sample = max(-32768, min(32767, int(sample)))
            wav.writeframes(struct.pack("h", sample))


def generate_shoot_sound():
    """Generate a 'pew pew' laser shooting sound"""
    sample_rate = 22050
    duration = 0.15  # seconds
    num_samples = int(sample_rate * duration)

    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency sweep from high to low
        freq = 800 - (t / duration) * 600
        # Square wave with decay
        value = (
            20000
            * (1 - t / duration)
            * (1 if math.sin(2 * math.pi * freq * t) > 0 else -1)
        )
        samples.append(value)

    return samples


def generate_explosion_sound():
    """Generate a cartoon explosion/splat sound (slapstick style)"""
    sample_rate = 22050
    duration = 0.4  # seconds
    num_samples = int(sample_rate * duration)

    samples = []
    import random

    random.seed(42)  # Reproducible

    for i in range(num_samples):
        t = i / sample_rate
        # White noise with exponential decay
        decay = math.exp(-t * 8)
        noise = random.uniform(-1, 1)
        # Add some low frequency rumble
        rumble = math.sin(2 * math.pi * 80 * t) * 0.3
        value = 25000 * decay * (noise * 0.7 + rumble * 0.3)
        samples.append(value)

    return samples


def generate_boing_sound():
    """Generate a cartoon boing/spring sound for slapstick"""
    sample_rate = 22050
    duration = 0.3  # seconds
    num_samples = int(sample_rate * duration)

    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency goes up quickly then oscillates
        if t < 0.1:
            freq = 200 + (t / 0.1) * 400
        else:
            # Oscillating decay
            decay = math.exp(-(t - 0.1) * 5)
            freq = 600 + 200 * math.sin((t - 0.1) * 30) * decay

        # Triangle wave
        phase = (freq * t) % 1.0
        if phase < 0.5:
            wave = phase * 4 - 1
        else:
            wave = 3 - phase * 4

        envelope = 1.0 if t < 0.1 else math.exp(-(t - 0.1) * 4)
        value = 20000 * wave * envelope
        samples.append(value)

    return samples


def generate_hit_sound():
    """Generate a cartoon hit/thwack sound"""
    sample_rate = 22050
    duration = 0.1  # seconds
    num_samples = int(sample_rate * duration)

    samples = []
    import random

    random.seed(123)

    for i in range(num_samples):
        t = i / sample_rate
        # Short burst of filtered noise
        decay = math.exp(-t * 20)
        noise = random.uniform(-1, 1)
        # Add a thump
        thump = math.sin(2 * math.pi * 150 * t) * math.exp(-t * 10)
        value = 28000 * decay * (noise * 0.5 + thump * 0.5)
        samples.append(value)

    return samples


def main():
    create_directory()

    # Generate all sound effects
    shoot_samples = generate_shoot_sound()
    generate_wave(
        "/home/rowan/horseshooter/HorseShooter/assets/sounds/shoot.wav", shoot_samples
    )
    print("Created shoot.wav")

    explosion_samples = generate_explosion_sound()
    generate_wave(
        "/home/rowan/horseshooter/HorseShooter/assets/sounds/explosion.wav",
        explosion_samples,
    )
    print("Created explosion.wav")

    boing_samples = generate_boing_sound()
    generate_wave(
        "/home/rowan/horseshooter/HorseShooter/assets/sounds/boing.wav", boing_samples
    )
    print("Created boing.wav")

    hit_samples = generate_hit_sound()
    generate_wave(
        "/home/rowan/horseshooter/HorseShooter/assets/sounds/hit.wav", hit_samples
    )
    print("Created hit.wav")

    print("\nAll sound effects created successfully!")


if __name__ == "__main__":
    main()
