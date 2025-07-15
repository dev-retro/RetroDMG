# Emulator Feature Details: File-by-File Mapping


# DMG (Original Game Boy) Implementation

## Sources/RetroDMG/Bus.swift
- Implements: System bus, memory controller, memory-mapped IO, RAM, VRAM, OAM, boot ROM, cartridge access
- Edge Cases: Echo RAM mirroring, FEA0–FEFF unusable, DMA blocking, boot ROM mapping, interrupt registers, timer registers, input, cycle-accurate DMA
- Missing: Sound/APU, Serial/Link cable, STOP opcode, undocumented/illegal opcodes, hardware revision differences

## Sources/RetroDMG/CPU.swift
- Implements: CPU core, instruction set, register/timer/interrupt logic, HALT, IME, instruction timing, DMA halt logic
- Edge Cases: HALT bug, IME delay, interrupt priorities, timer overflow, modulo reload, cycle counting
- Missing: STOP opcode (0x10), Sound/APU, Serial/Link cable, undocumented/illegal opcodes, hardware revision differences

## Sources/RetroDMG/PPU.swift
- Implements: PPU (graphics), scanline rendering, BG/window/sprite logic, FIFO, palette mapping, OAM scan, window trigger, sprite priority
- Edge Cases: Window trigger, OAM scan (10 sprites/scanline), sprite priority, palette mapping, $8000/$8800 addressing, signed/unsigned tile index
- Missing: Sound/APU, Serial/Link cable, hardware revision differences

## Sources/RetroDMG/MBC.swift & CartTypes/
- Implements: MBC1, MBC2, MBC3, MBC5, NoMBC, RAM/ROM banking, battery saves
- Edge Cases: RAM enable, ROM/RAM bank switching, battery-backed RAM, cartridge header mapping
- Missing: MBC3 RTC (partial), hardware revision differences

## Sources/RetroDMG/Registers.swift
- Implements: CPU registers, flags, IME, register read/write logic
- Edge Cases: Flag masking, AF register masking, IME handling
- Missing: hardware revision differences

## Sources/RetroDMG/RetroDMG.swift
- Implements: Platform interface, input handling, state reporting, save/load, debug state, persistence API
- Edge Cases: Input interrupt, state inspection, battery save/load, debug reporting
- Missing: advanced debugging, hardware revision differences

## Sources/RetroDMG/Extensions.swift & Utilities.swift
- Implements: Utility extensions for bit manipulation, array safety
- Edge Cases: Bit masking, safe array access
- Missing: None (utility only)

# CGB (Game Boy Color) Implementation

## Sources/RetroDMG/Bus.swift
- Missing: CGB-specific registers (VRAM/WRAM banking, color palettes, DMA, speed switch, infrared)

## Sources/RetroDMG/CPU.swift
- Missing: CGB-specific instructions (STOP with speed switch, double-speed mode), hardware revision differences

## Sources/RetroDMG/PPU.swift
- Missing: CGB color palettes (BG/OBJ, 32 palettes, FF68–FF6B registers), VRAM banking (two banks, attribute maps, FF4F register), CGB priority and attribute maps (per-tile attributes, palette selection, priority bits)

## Sources/RetroDMG/MBC.swift & CartTypes/
- Missing: CGB-specific cartridge features (CGB flag, hardware differences)

## Sources/RetroDMG/Registers.swift
- Missing: CGB-specific registers (KEY0, KEY1, speed switch, WRAM bank, palette registers)

## Sources/RetroDMG/RetroDMG.swift
- Missing: CGB mode detection and handling (boot ROM, hardware registers, double-speed mode)

## General Missing Features (Both DMG & CGB)
- Sound/APU: Not implemented (registers and logic missing)
- Serial/Link cable: Not implemented (registers and logic missing)
- SGB/AGB compatibility: Not implemented (special registers, border rendering, palette mapping)
- Full test ROM compatibility: Needs more test suite coverage (including STOP, undocumented opcodes, hardware revision differences, timing tests)

---

This mapping is based on Pan Docs, SameBoy, and a line-by-line review of the codebase as of July 2025.
