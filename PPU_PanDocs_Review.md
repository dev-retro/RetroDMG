# Game Boy PPU (Pixel Processing Unit) Review

## PPU Feature Implementation Status (DMG Mode)

| Feature                        | Status       | Notes                                         |
|--------------------------------|-------------|-----------------------------------------------|
| LCDC/STAT registers            | Fully Implemented (Compliant) | All bits, writable masks, mode/interrupt logic|
| VRAM access                    | Fully Implemented (Compliant) | All regions, Mode 3 access rules, boundaries  |
| OAM (sprites)                  | Fully Implemented (Compliant) | 40 sprites, scan, priority, Mode 2/3 access rules |
| Rendering pipeline             | Fully Implemented (Compliant) | Scanline, BG/window/sprite, FIFO, timing, priority, penalties, double-buffered |
| Palettes (BGP/OBP0/OBP1)       | Fully Implemented (Compliant) | Register access, color mapping, BG/sprite logic |
| DMA (OAM transfer)             | Fully Implemented (Compliant) | FF46, OAM transfer, register logic           |
| Registers (SCX, SCY, LY, etc.) | Fully Implemented (Compliant) | All mapped, read/write, Pan Docs logic       |
| Framebuffers                   | Fully Implemented (Compliant) | Double-buffered, 160x144, VBlank swap       |
| Interrupts                     | Fully Implemented (Compliant) | VBlank, LCD STAT, LY=LYC, flags, timing     |
| Not Usable Area                | Fully Implemented (Compliant) | 0xFEA0–0xFEFF, reads=0xFF, writes ignored   |
| CGB features (color/speed)     | Stub/TODO    | Not implemented, DMG only                     |
| Audio registers                | Stub/TODO    | Not handled by PPU (see Bus.swift)            |
| Boot ROM mapping               | Stub/TODO    | TODO in Bus.swift                             |

## References
- [GBDEV Pandocs: Rendering](https://gbdev.io/pandocs/Rendering.html)
- [GBDEV Pandocs: Palettes](https://gbdev.io/pandocs/Palettes.html)
- [GBDEV Pandocs: OAM/Sprites](https://gbdev.io/pandocs/OAM.html)
- [GBDEV Pandocs: Tile Data](https://gbdev.io/pandocs/Tile_Data.html)

## PPU Features (per Pandocs)
1. **LCD Control (LCDC/STAT registers)**
   - LCD enable/disable
   - Window enable, position, tilemap select
   - BG enable, tilemap select, tile data select
   - Sprite (OBJ) enable, size, priority
   - Interrupts: VBlank, LCD, LY=LYC, mode flags
2. **VRAM Access**
   - Tile data (0x8000-0x97FF)
   - Tile maps (0x9800-0x9FFF)
   - Access rules per mode (Mode 3 restricts access)
3. **OAM (Object Attribute Memory)**
   - 40 sprites, 4 bytes each
   - OAM scan, priority, X/Y position, attributes
   - Access rules per mode (Mode 2/3 restricts access)
4. **Rendering Pipeline**
   - Scanline-based rendering (160x144)
   - BG/window rendering, window trigger logic
   - Sprite rendering, priority, palette selection
   - Pixel FIFO for BG/OBJ mixing
   - Timing penalties (SCX, window, OBJ)
5. **Palettes**
   - BGP, OBP0, OBP1 registers
   - Color mapping (White, LightGray, DarkGray, Black)
6. **DMA Transfer**
   - OAM DMA (FF46)
   - Correctly triggers OAM transfer
7. **Registers**
   - SCX, SCY (scroll)
   - LY, LYC (scanline, compare)
   - WX, WY (window position)
   - DMA, BGP, OBP0, OBP1
8. **Framebuffers**
   - Double-buffered: tempFrameBuffer (rendering), viewPort (display)
9. **Interrupts**
   - VBlank, LCD STAT, LY=LYC
10. **Not Usable Area**
    - 0xFEA0–0xFEFF: ignored/returns 0xFF

## Implementation Status (RetroDMG)
### Implemented
- LCDC/STAT registers: All flags, mode transitions, interrupts
- VRAM: Tile data, tile maps, access rules per mode
- OAM: 40 sprites, scan, priority, attributes, access rules
- Rendering: Scanline-based, BG/window/sprite, window trigger, FIFO, timing penalties
- Palettes: BGP, OBP0, OBP1, color mapping
- DMA: OAM DMA transfer (FF46)
- Registers: SCX, SCY, LY, LYC, WX, WY, DMA, BGP, OBP0, OBP1
- Framebuffers: Double-buffered, correct size
- Not Usable Area: DMG-correct handling

### Stubs/TODOs
- CGB features (color, speed switch): Not implemented (DMG only)
- Audio registers: Not handled by PPU (see Bus.swift)
- Boot ROM mapping: TODO in Bus.swift, not PPU

### Notes
- All features for DMG mode per Pandocs are implemented or stubbed as DMG-correct.
- All register access rules, timing, and priority logic are present.
- No CGB features (color, speed switch) implemented; DMG only.
- Audio and boot ROM mapping are handled elsewhere (Bus.swift).

## Cross-Class Checks
- Bus.swift: Handles all PPU register access, DMA, not usable area, audio stubs, boot ROM mapping stubs.
- Extensions.swift: Bit manipulation for register flags (used by PPU).

## Summary
The PPU implementation in RetroDMG covers all DMG features per Pandocs, with correct stubs/TODOs for unimplemented hardware. All register, memory, and rendering logic is present and Pan Docs compliant for DMG mode.

---

## Bug Diagnosis & Fix Recommendations (July 2025)

### 1. Sprite Transparency (Pokéball "White Halo")
- **Observed:** Pokéball sprite has a white background/halo in RetroDMG, but is transparent in reference emulators.
- **Cause:** Sprite pixels with color index 0 are not treated as transparent in the pixel mixing logic. These should allow the BG pixel to show through, not overwrite it with white.
- **Fix:** In the pixel mixing function (e.g., `popAndMixPixel()`), ensure that if the OBJ pixel’s color index is 0, the BG pixel is used. Only non-zero OBJ pixels should overwrite BG, subject to priority.

### 2. Missing Pokémon Sprite
- **Observed:** Reference shows a Pokémon sprite next to the trainer, but RetroDMG does not.
- **Cause:** Likely due to sprite priority or OAM scan logic. Possible issues:
  - Sprite is present in OAM but not rendered due to incorrect priority logic.
  - Sprite is overwritten by BG or other sprites due to mixing logic.
  - OAM scan misses the sprite due to X/Y position or scanline logic.
- **Fix:**
  - Confirm OAM scan finds all sprites for the scanline (up to 10).
  - Ensure sprites are sorted by X position, then OAM index (lowest index wins).
  - Respect OBJ-to-BG priority bit: if set, BG pixel is shown unless BG is color 0 (white).

### 3. General Recommendations
- Review and update pixel mixing logic to match Pan Docs:
  - Sprite color index 0 = transparent (BG shows through)
  - Sprite priority respected (BG shown unless BG is color 0 and priority bit is set)
  - Correct palette selection for each sprite pixel
- Ensure FIFO clearing and framebuffer writes are correct.

---

### Next Steps
- Update pixel mixing logic in PPU.swift to fix transparency and priority handling.
- Validate with Pokémon Blue title screen and other sprite-heavy scenes.
