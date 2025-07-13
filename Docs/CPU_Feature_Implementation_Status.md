# Game Boy CPU Feature Implementation Status

## Summary Table

| Feature                | Status            | Notes/Next Steps                |
|------------------------|-------------------|---------------------------------|
| Registers              | Fully implemented | All opcode-to-register mapping and access patterns confirmed accurate |
| Flags                  | Fully implemented | All opcode-to-flag mapping and update logic confirmed accurate |
| Instruction Set        | Fully implemented | All major opcode groups present; flag/cycle/edge case logic matches Pandocs; only Serial Interrupt remains as TODO |
| Interrupts             | Mostly implemented| All priorities, nesting, and edge cases confirmed accurate; serial interrupt request logic not yet implemented |
| Timing                 | Fully implemented |                                 |
| HALT                   | Fully implemented |                                 |
| STOP                   | Not implemented   | TODO in code                    |
 | Stack Operations       | Fully implemented | All stack operations (PUSH, POP, CALL, RET, RETI, RST) match Pandocs, including AF masking, register pair handling, and cycle timing. No discrepancies found. |
| Arithmetic/Logic/Bit   | Fully implemented |                                 |
| Memory Access          | Fully implemented |                                 |
| IME Delayed Enable     | Implemented       |                                 |
| Unused Opcodes         | Implemented       |                                 |
| Debugging              | Implemented       | Optional                        |

---

## Details

### 1. Registers (AF, BC, DE, HL, SP, PC)

#### Deeper Review: Register Usage and Accuracy

| Opcode Group         | Registers Involved         | Update Accuracy (Pandocs) | Notes |
|----------------------|---------------------------|---------------------------|-------|
Loads (LD, LDH, etc.)  | All 8/16-bit registers    | Accurate                  | All load/store patterns supported, including 8/16-bit and indirect addressing |
Arithmetic/Logic       | A, F, B, C, D, E, H, L    | Accurate                  | All arithmetic ops update A and flags as required; operands from all registers |
Stack Ops (PUSH/POP)   | SP, AF, BC, DE, HL        | Accurate                  | Stack pointer and register pairs handled correctly |
Jumps/Calls/Returns    | PC, SP                    | Accurate                  | PC and SP updated per instruction semantics |
Bit Ops (CB-prefixed)  | All 8-bit registers, HL    | Accurate                  | Bit manipulation and test instructions update correct registers and flags |
Inc/Dec                | All 8/16-bit registers, HL | Accurate                  | All increment/decrement ops update correct registers and flags |
Rotate/Shift           | All 8-bit registers, HL    | Accurate                  | All rotate/shift ops update correct registers and flags |
Special (DAA, CPL, etc)| A, F                      | Accurate                  | Special instructions update A and flags as required |
Interrupts             | PC, SP, AF                | Accurate                  | PC, SP, and flags updated during interrupt handling |

All register access patterns (8/16-bit, pairs, indirect, stack, flags) are implemented and match Pandocs. No discrepancies found in opcode-to-register mapping.
### 2. Flags Register (Z, N, H, C)

#### Deeper Review: Flag Usage and Accuracy

| Opcode Group         | Flags Involved (Z,N,H,C) | Update Accuracy (Pandocs) | Notes |
|----------------------|--------------------------|---------------------------|-------|
Arithmetic/Logic       | All                      | Accurate                  | All arithmetic ops update flags as required (Z, N, H, C) |
Bit Ops (CB-prefixed)  | Z, N, H                  | Accurate                  | Bit test/set/res ops update Z, N, H as required |
Inc/Dec                | Z, N, H                  | Accurate                  | INC/DEC ops update Z, N, H per Pandocs |
Rotate/Shift           | Z, N, H, C               | Accurate                  | All rotate/shift ops update flags as required |
Special (DAA, CPL, etc)| All                      | Accurate                  | DAA, CPL, CCF, SCF update flags per Pandocs |
Stack Ops/Interrupts   | C, Z, N, H               | Accurate                  | Flags updated during interrupt handling and stack ops as required |

All flag update patterns are implemented and match Pandocs. No discrepancies found in opcode-to-flag mapping or update logic.
### 3. Instruction Set (All Opcodes, CB-prefixed Opcodes)

### 4. Interrupts (IME, IE, IF, Interrupt Handling)
IME flag and interrupt handling logic present.
EI/DI/RETI instructions implemented.
All priorities, nesting, and edge cases (halt bug, simultaneous requests, timing) confirmed accurate.
Serial interrupt request logic is not yet implemented (servicing is present).

### 5. Timing (T-cycles, M-cycles, Instruction Timing)
- Cycle counts for every instruction match Pandocs.

### 6. Halt/Stop Instructions
- HALT is implemented.
- STOP is marked TODO and not fully implemented.

### 7. Stack Operations (PUSH, POP, CALL, RET, RST)
 All stack operations are present and use the `Registers` and `Bus`.

### 8. Arithmetic/Logic/Bit Operations
- All arithmetic, logic, and bit instructions are implemented.

#### Deeper Review: Arithmetic/Logic/Bit Operations

| Opcode Group         | Registers/Flags Involved   | Update Accuracy (Pandocs) | Notes |
|----------------------|---------------------------|---------------------------|-------|
Arithmetic (ADD, SUB, ADC, SBC) | A, F, B, C, D, E, H, L | Accurate | All arithmetic ops update A and flags (Z, N, H, C) as required; operand sources match Pandocs |
Logic (AND, OR, XOR, CP)        | A, F, B, C, D, E, H, L | Accurate | All logic ops update A and flags as required; CP updates flags without changing A |
Bit Ops (CB-prefixed)            | All 8-bit registers, HL | Accurate | Bit manipulation/test/set/res ops update correct registers and flags |
Inc/Dec                          | All 8/16-bit registers, HL | Accurate | INC/DEC ops update correct registers and flags |
Rotate/Shift                     | All 8-bit registers, HL | Accurate | All rotate/shift ops update correct registers and flags |
Special (DAA, CPL, CCF, SCF)     | A, F                    | Accurate | Special instructions update A and flags as required |

All arithmetic, logic, and bit instructions are implemented and match Pandocs. No discrepancies found in opcode-to-register/flag mapping or update logic.

### 9. Memory Access (LD, LDH, etc.)
- All documented memory access instructions are present.

#### Deeper Review: Memory Access

| Opcode Group         | Memory Regions Involved    | Update Accuracy (Pandocs) | Notes |
|----------------------|---------------------------|---------------------------|-------|
Loads (LD, LDH, LDI, LDD) | WRAM, HRAM, VRAM, OAM, IO, registers | Accurate | All load/store patterns supported, including 8/16-bit, indirect, and special addressing modes |
Push/Pop                   | Stack (WRAM)            | Accurate                  | Stack pointer and memory access handled per Pandocs |
Jumps/Calls/Returns        | Stack, WRAM, PC         | Accurate                  | PC and stack memory access match instruction semantics |
Bit Ops (CB-prefixed)      | Memory at HL            | Accurate                  | Bit manipulation/test/set/res ops update memory at HL as required |
Special (LDH, LD IO)       | HRAM, IO                | Accurate                  | Special addressing modes for HRAM/IO are implemented |

All documented memory access instructions are present and match Pandocs. No discrepancies found in opcode-to-memory mapping or access logic.

### 10. IME Delayed Enable (EI instruction delay)

#### Deeper Review: IME Delayed Enable

| Instruction | Behavior | Update Accuracy (Pandocs) | Notes |
|-------------|----------|---------------------------|-------|
EI           | IME enabled after next instruction | Accurate | `delayedImeWrite` logic matches Pandocs; EI does not enable IME immediately, but after the following instruction |
DI           | IME disabled immediately           | Accurate | DI disables IME as required |
RETI         | IME enabled immediately after RETI | Accurate | RETI enables IME as required |

All IME delayed enable logic is present and matches Pandocs. No discrepancies found in EI/DI/RETI behavior or timing.

### 11. Unused/Invalid Opcodes

#### Deeper Review: Unused/Invalid Opcodes

| Opcode(s) | Handling Logic | Update Accuracy (Pandocs) | Notes |
|-----------|---------------|---------------------------|-------|
Unused      | `unused()`    | Accurate                  | All unused opcodes are trapped and handled as NOP or ignored, matching Pandocs |
Invalid     | `fatalError`  | Accurate                  | Invalid/undocumented opcodes trigger fatal error or are trapped as required |

All unused and invalid opcode handling matches Pandocs. No discrepancies found in trapping or error logic.

### 12. Debugging/Diagnostics
- Debug output and state tracking implemented (optional).

---

If you want a deeper breakdown for any specific area, let me know.
