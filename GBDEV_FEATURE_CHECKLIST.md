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
