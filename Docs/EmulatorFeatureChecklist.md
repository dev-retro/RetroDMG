# Game Boy Emulator Feature Checklist (DMG & CGB)

## DMG (Original Game Boy) Emulator Feature Checklist

| Feature                        | Implemented | Edge Cases/Notes |
|--------------------------------|-------------|------------------|
| CPU (GB-Z80)                   | Yes         | Instruction timing, HALT bug, IME delay, interrupt priorities, **STOP opcode missing**, undocumented/illegal opcodes, hardware revision differences |
| Memory Map                     | Yes         | Echo RAM mirroring, FEA0–FEFF unusable, boot ROM mapping, hardware revision differences |
| PPU (Graphics: BG, Window, OBJ)| Yes         | Window trigger, sprite priority, OAM scan, FIFO, palette mapping, hardware revision differences |
| Tile Data/Maps                 | Yes         | $8000/$8800 addressing, signed/unsigned tile index, palette swaps, hardware revision differences |
| OAM (Sprite Attribute Memory)   | Yes         | 10 sprites/scanline, priority, transparency, OBJ size, hardware revision differences |
| Palettes (BGP, OBP0, OBP1)     | Yes         | Palette mapping, color index 0 transparency for OBJ, hardware revision differences |
| Timers (DIV, TIMA, TMA, TAC)   | Yes         | Timer overflow, modulo reload, timer interrupt timing, hardware revision differences |
| Input (JOYP)                   | Yes         | D-pad/buttons separation, input interrupt, masking, hardware revision differences |
| DMA (OAM transfer)             | Yes         | Cycle-accurate transfer, blocking writes during DMA, hardware revision differences |
| Interrupts (VBlank, LCD, etc.) | Yes         | IME, IE, IF, priorities, nested interrupts, delayed EI, hardware revision differences |
| Cartridge/MBC support          | Yes         | MBC1, MBC2, MBC3, MBC5, NoMBC, RAM/ROM banking, battery saves, hardware revision differences |
| Boot ROM loading/mapping       | Yes         | FF50 mapping, initial register values, hardware revision differences |
| Save states/battery saves      | Yes         | RAM persistence, cartridge header mapping, hardware revision differences |
| Sound/APU                      | No          | Registers stubbed, not implemented |
| Serial/Link cable              | No          | Registers stubbed, not implemented |
| Real-time clock (RTC)          | Partial     | MBC3 RTC not fully implemented |
| Debugging/State inspection     | Yes         | Register/state reporting, memory inspection, hardware revision differences |
| Test ROM compatibility         | Partial     | Not all edge cases covered, needs more test suite coverage (including STOP, undocumented opcodes, hardware revision differences, timing tests) |

---

## CGB (Game Boy Color) Feature Checklist

| Feature                        | Implemented | Edge Cases/Notes |
|--------------------------------|-------------|------------------|
| CGB mode detection             | No          | FF4D, FF4F, FF70 registers, boot ROM differences, double-speed mode, STOP opcode (speed switch), hardware revision differences |
| VRAM banking                   | No          | Two banks, attribute maps, bank switching, FF4F register, hardware revision differences |
| WRAM banking                   | No          | FF70 register, 8 banks, hardware revision differences |
| Color palettes (BG/OBJ)        | No          | FF68–FF6B registers, 32 BG/OBJ palettes, hardware revision differences |
| CGB-specific hardware registers| No          | KEY0, KEY1, speed switch, infrared port, hardware revision differences |
| CGB DMA (VRAM DMA)             | No          | FF51–FF55 registers, HBlank/General DMA, hardware revision differences |
| CGB priority and attributes    | No          | BG/OBJ priority, palette selection, attribute maps, hardware revision differences |
| CGB test ROM compatibility     | No          | Needs full test suite coverage (including STOP, double-speed mode, undocumented opcodes, hardware revision differences, timing tests) |
| SGB/AGB compatibility          | No          | Not implemented |

---

See `EmulatorFeatureDetails.md` for a file-by-file mapping and edge case notes.
