# GBDEV Feature Checklist (RetroDMG)

This checklist maps gbdev.io Pan Docs topics to the current RetroDMG codebase.

Legend: [x] implemented, [~] partial, [ ] missing

## Implemented (DMG focus)
- [x] CPU instruction set and core execution (Sources/RetroDMG/CPU.swift, Sources/RetroDMG/Registers.swift)
- [x] Interrupt dispatch (VBlank/LCD/Timer/Joypad) (Sources/RetroDMG/CPU.swift)
- [x] System bus + memory map + IO registers (Sources/RetroDMG/Bus.swift)
- [x] Timers (DIV/TIMA/TMA/TAC) (Sources/RetroDMG/CPU.swift, Sources/RetroDMG/Bus.swift)
- [x] OAM DMA (FF46) (Sources/RetroDMG/Bus.swift)
- [x] PPU/LCD pipeline, BG/Window/OBJ, palettes (Sources/RetroDMG/PPU.swift)
- [x] Joypad input (FF00) (Sources/RetroDMG/Bus.swift, Sources/RetroDMG/RetroDMG.swift)
- [x] Cartridge MBCs: NoMBC, MBC1, MBC2, MBC3+RTC, MBC5 (Sources/RetroDMG/MBC.swift, Sources/RetroDMG/CartTypes/*)
- [x] Boot ROM mapping (basic DMG behavior) (Sources/RetroDMG/Bus.swift, Sources/RetroDMG/RetroDMG.swift)

## Missing / Partial (main areas)
- [ ] APU audio (NR10-NR52 + wave RAM)
- [ ] Serial/link cable (SB/SC + serial interrupt)
- [ ] CGB features: double-speed, VRAM/WRAM banking, HDMA, CGB palettes/attributes
- [ ] SGB features: command packets, borders, VRAM transfers
- [ ] Additional MBCs/peripherals: MMM01, MBC6, MBC7, HuC1/HuC3, M161, IR, etc.
- [ ] Accuracy edge cases: timer obscure behavior, OAM corruption, STAT timing quirks, HALT bug

## APU Detailed Checklist (DMG)
- [ ] APU: Add new APU module and hook it into the main loop timing (step per CPU cycles).
- [ ] APU: Wire FF10-FF26 and FF30-FF3F reads/writes in Sources/RetroDMG/Bus.swift.
- [ ] APU: Implement NR52 power on/off behavior (reset registers, disable channels, read-only rules).
- [ ] APU: Implement register read masks (unused bits read as 1/0 per Pan Docs).
- [ ] APU: Implement frame sequencer (512 Hz) and derive ticks for:
- [ ] APU: Length counters (256 Hz) for all channels (CH1/2/4 length 64, CH3 length 256).
- [ ] APU: Sweep unit (128 Hz) for CH1 (NR10).
- [ ] APU: Volume envelopes (64 Hz) for CH1/2/4 (NR12/NR22/NR42).
- [ ] APU: Channel 1 (square + sweep): duty, length, envelope, frequency, trigger, sweep overflow.
- [ ] APU: Channel 2 (square): duty, length, envelope, frequency, trigger.
- [ ] APU: Channel 3 (wave): NR30 DAC enable, wave RAM (32 samples), length, volume, frequency, trigger.
- [ ] APU: Channel 4 (noise): LFSR, width mode, divisor/clock, length, envelope, trigger.
- [ ] APU: Channel DAC enable rules (channel off when DAC disabled).
- [ ] APU: Mixer (NR50/NR51) to left/right outputs and per-channel routing.
- [ ] APU: NR52 channel status bits reflect active channels.

## APU API Layer Checklist (RetroDMG)
- [ ] API: Decide on audio output mode (pull, push, or both).
- [ ] API: Define stable sample format (recommended: interleaved stereo s16le).
- [ ] API: Expose `dequeueAudio(maxFrames:)` for pull-based consumers.
- [ ] API: Optionally expose `setAudioSink(_:)` for push-based consumers.
- [ ] API: Add ring buffer in APU (or RetroDMG) for audio frames.
- [ ] API: Define sample rate configuration (44_100 or 48_000).
- [ ] API: Implement resampling from APU clock to output rate.
- [ ] API: Silence output when NR52 disables APU (do not stall).
- [ ] API: Add settings hooks in Sources/RetroDMG/Models/DMGSettings.swift (sampleRate, bufferFrames, format, enabled).

## Touchpoints (where work would land)
| Area | gbdev reference | Touchpoints in this repo |
| --- | --- | --- |
| APU audio | https://gbdev.io/pandocs/Audio_Registers.html | Add new APU module; wire IO in Sources/RetroDMG/Bus.swift (FF10-FF26, FF30-FF3F); step APU from main loop in Sources/RetroDMG/RetroDMG.swift or CPU tick |
| Serial/link cable | https://gbdev.io/pandocs/Serial_Data_Transfer_(Link_Cable).html | Implement SB/SC in Sources/RetroDMG/Bus.swift; complete serial interrupt path in Sources/RetroDMG/CPU.swift (`processInterrupt` TODO); add external serial I/O surface in Sources/RetroDMG/RetroDMG.swift |
| CGB speed switch | https://gbdev.io/pandocs/CGB_Registers.html | Implement KEY1/FF4D in Sources/RetroDMG/Bus.swift; adjust CPU timing in Sources/RetroDMG/CPU.swift; expose mode in settings if needed |
| CGB VRAM/WRAM banking | https://gbdev.io/pandocs/CGB_Registers.html | Add VBK/FF4F and SVBK/FF70 in Sources/RetroDMG/Bus.swift; extend PPU VRAM storage in Sources/RetroDMG/PPU.swift |
| CGB HDMA | https://gbdev.io/pandocs/CGB_Registers.html | Add HDMA registers and transfer logic in Sources/RetroDMG/Bus.swift; coordinate with PPU timing |
| CGB palettes/attributes | https://gbdev.io/pandocs/Palettes.html | Extend Sources/RetroDMG/PPU.swift with CGB palettes and BG/OBJ attributes; add palette IO regs in Sources/RetroDMG/Bus.swift |
| SGB features | https://gbdev.io/pandocs/SGB_VRAM_Transfer.html | New SGB command handling; likely new module + hooks from Sources/RetroDMG/Bus.swift and Sources/RetroDMG/RetroDMG.swift |
| Additional MBCs | https://gbdev.io/pandocs/MBCs.html | Add cart types under Sources/RetroDMG/CartTypes/; extend type parsing in Sources/RetroDMG/MBC.swift and Sources/RetroDMG/Models/CartridgeHeader.swift |
| Timer edge cases | https://gbdev.io/pandocs/Timer_Obscure_Behaviour.html | Refine timer edge behavior in Sources/RetroDMG/CPU.swift (`updateTimer`) |
| OAM corruption | https://gbdev.io/pandocs/OAM_Corruption.html | Add OAM corruption timing effects in Sources/RetroDMG/Bus.swift and/or Sources/RetroDMG/PPU.swift |
| STAT timing quirks | https://gbdev.io/pandocs/STAT.html | Tighten mode transitions and STAT IRQ timing in Sources/RetroDMG/PPU.swift |
| HALT bug | https://gbdev.io/pandocs/HALT_Bug.html | Model HALT bug in Sources/RetroDMG/CPU.swift (halt/resume path) |

## Notes
- This list focuses on core gbdev hardware features. UI/audio output, input wiring, and integration are handled by the consuming app (see Sources/RetroDMG/RetroDMG.swift).
