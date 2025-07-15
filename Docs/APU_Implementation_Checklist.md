# Game Boy APU Implementation Checklist

This checklist covers all major aspects of implementing the Audio Processing Unit (APU) for a Game Boy emulator, including practical details, register mappings, timing, mixing, and edge cases. Use this as a step-by-step guide for development and validation.

```markdown
- [ ] 1. General APU Architecture
    - [ ] Implement memory-mapped I/O for all APU registers (NR10–NR52)
    - [ ] Implement master enable/disable (NR52)
    - [ ] Implement stereo mixing and output (NR50/NR51)
    - [ ] Support correct sample rate output and resampling (e.g., blip_buf, FIR/low-pass filter)

- [ ] 2. Channel 1 (Square 1: Pulse + Sweep)
    - [ ] NR10: Sweep (period, direction, shift)
    - [ ] NR11: Duty cycle, length timer
    - [ ] NR12: Envelope (initial volume, direction, period)
    - [ ] NR13/NR14: Frequency (11 bits), trigger, length enable
    - [ ] Implement sweep logic and edge cases (overflow, disable, retrigger)
    - [ ] Implement duty cycle waveform (4 types, 8 steps)
    - [ ] Implement envelope timer and volume changes
    - [ ] Implement length timer (auto-shutoff)
    - [ ] Implement DAC enable/disable logic

- [ ] 3. Channel 2 (Square 2: Pulse)
    - [ ] NR21: Duty cycle, length timer
    - [ ] NR22: Envelope (initial volume, direction, period)
    - [ ] NR23/NR24: Frequency (11 bits), trigger, length enable
    - [ ] Implement duty cycle waveform (same as CH1)
    - [ ] Implement envelope and length timer
    - [ ] Implement DAC enable/disable logic

- [ ] 4. Channel 3 (Wave)
    - [ ] NR30: DAC enable
    - [ ] NR31: Length timer
    - [ ] NR32: Volume (2 bits: mute, 100%, 50%, 25%)
    - [ ] NR33/NR34: Frequency (11 bits), trigger, length enable
    - [ ] Implement waveform RAM (16 bytes, 32 4-bit samples)
    - [ ] Implement waveform playback, length timer, volume control
    - [ ] Implement DAC enable/disable logic

- [ ] 5. Channel 4 (Noise)
    - [ ] NR41: Length timer
    - [ ] NR42: Envelope (initial volume, direction, period)
    - [ ] NR43: Frequency, polynomial counter (LFSR width, divisor, clock shift)
    - [ ] NR44: Trigger, length enable
    - [ ] Implement LFSR noise generation (7/15 bits)
    - [ ] Implement envelope and length timer
    - [ ] Implement DAC enable/disable logic

- [ ] 6. Frame Sequencer & Timing
    - [ ] Implement 512Hz frame sequencer (clocks length, envelope, sweep)
    - [ ] Ensure correct timing for all counters (length: 256Hz, envelope: 64Hz, sweep: 128Hz)
    - [ ] Handle DIV register writes and edge cases (early/late clocks, double-speed mode)

- [ ] 7. Mixing & Output
    - [ ] Mix all channel outputs to left/right (NR50/NR51)
    - [ ] Apply master volume and per-channel volume
    - [ ] Output samples at correct rate (e.g., 44.1kHz/48kHz)
    - [ ] Apply low-pass filter or blip_buf for resampling

- [ ] 8. Edge Cases & Quirks
    - [ ] Handle "zombie mode" (obscure behavior when triggering with DAC off)
    - [ ] Handle retriggering, envelope/sweep quirks
    - [ ] Handle register read/write quirks (some registers return 0, some are write-only)
    - [ ] Pass blargg’s test ROMs and other audio test suites

- [ ] 9. Testing & Validation
    - [ ] Use test ROMs (blargg, gbdev, custom) to validate APU behavior
    - [ ] Compare output to reference emulators (SameBoy, BGB, Gambatte)
    - [ ] Validate with real-world game audio (boot sound, SML, Tetris, Zelda, etc.)
    - [ ] Test stereo output, buffer management, and edge cases (timing, pops/cracks)
```
